import os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'True'

import torch
import torch.nn as nn
from quant_dorefa import *
from timm.models import create_model, safe_model_name, resume_checkpoint, load_checkpoint, \
    convert_splitbn_model, model_parameters
from timm.utils import *
from timm.loss import LabelSmoothingCrossEntropy, SoftTargetCrossEntropy, JsdCrossEntropy
from timm.optim import create_optimizer_v2, optimizer_kwargs
from timm.scheduler import create_scheduler
from timm.utils import ApexScaler, NativeScaler
from collections import OrderedDict
from model import *
import numpy as np
from spikingjelly.clock_driven.neuron import MultiStepLIFNode

# from rich import print

def write_data2coefile_int16(filename: str, data):
    """Write data (must be int16) to a coefficient file."""
    assert data.dtype == np.int16

    data = data.reshape(-1)
    with open(filename, 'w') as coefile:
        coefile.write("memory_initialization_radix=16;\n")
        coefile.write("memory_initialization_vector=\n")
        for i, value in enumerate(data):
            hex_value = f"{value & 0xFFFF:04X}"
            coefile.write(hex_value)
            if i < len(data) - 1:
                coefile.write(",\n")
            else:
                coefile.write("")
        coefile.write(";\n")

def write_data2coefile(filename: str, data):
    """Write data (must be int8) to a coefficient file."""
    assert data.dtype == np.int8

    data = data.reshape(-1)
    with open(filename, 'w') as coefile:
        coefile.write("memory_initialization_radix=16;\n")
        coefile.write("memory_initialization_vector=\n")
        for i, value in enumerate(data):
            hex_value = f"{value & 0xFF:02X}"
            coefile.write(hex_value)
            if i < len(data) - 1:
                coefile.write(",\n")
            else:
                coefile.write("")
        coefile.write(";\n")

def save_data_to_binfile(data):
    """ save weight to bin. """
    weight_data_list = []
    for i in range(data.shape[0]):
        for j in range(data.shape[1]):
            tmp = data[i][j].reshape(-1)
            tmp = np.concatenate((tmp, np.zeros((7), dtype=np.int8)), 0)
            weight_data_list.append(tmp)

    weight_bin_data = np.stack(weight_data_list).astype(np.int8)
    weight_bin_data = weight_bin_data.reshape(-1)
    file = open('../data4fpga_bin/weight_bin_new.bin', 'ab')
    for i in range(len(weight_bin_data)):
        file.write(weight_bin_data[i].tobytes())
    file.close()

def scale_cal(x, w_bit=8):
    """ quantized scale for FPGAs."""
    max_w = torch.max(torch.abs(x)).detach()
    scale = (2 ** (w_bit - 1) - 1) / max_w
    scale = 2 ** torch.floor(torch.log2(scale))
    return scale

def fixed_scale_weight_quantize_fn(x, scale=64):
    weight_q = torch.round(scale * x)
    return weight_q / scale

def read_txt_from_vivado(txt_file:str, shape):
    """
        args:
            txt_file --> 统一的前缀
            shape    --> e.g. (48, 32, 32)
        return:
            DATA (T, C, W, H)
    """
    lif_fpga_out_t0 = []
    lif_fpga_out_t1 = []
    lif_fpga_out_t2 = []
    lif_fpga_out_t3 = []
    with open(txt_file + '_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t0.append(float(line.strip()))
    f.close()
    lif_fpga_out_t0 = np.reshape(np.stack(lif_fpga_out_t0), shape)
    with open(txt_file + '_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t1.append(float(line.strip()))
    f.close()
    lif_fpga_out_t1 = np.reshape(np.stack(lif_fpga_out_t1), shape)
    with open(txt_file + '_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t2.append(float(line.strip()))
    f.close()
    lif_fpga_out_t2 = np.reshape(np.stack(lif_fpga_out_t2), shape)
    with open(txt_file + '_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t3.append(float(line.strip()))
    f.close()
    lif_fpga_out_t3 = np.reshape(np.stack(lif_fpga_out_t3), shape)
    return np.stack([lif_fpga_out_t0, lif_fpga_out_t1, lif_fpga_out_t2, lif_fpga_out_t3])


def Weights_reshape2Storage(weight, filename:str):
    """
        Change Weights storage Shape so that facilitate AXI brust read.
        ------------------------------
        |  0---->  |         |        |
        |  1---->  |         |        |
        |  2---->  |         |        |
        |  3---->  |         |        |
        ------------------------------
    """
    # assert weight.shape[0] == 384 and weight.shape[1] == 384
    m, n = weight.shape[1], weight.shape[0]

    weight = weight.T
    num = int(n / 16)
    weight_data_list = []
    for k in range(num):
        w00 = weight[:, 16*k:16*(k + 1)]
        for i in range(w00.shape[0]):
            for j in range(w00.shape[1]):
                weight_data_list.append(w00[i][j])

    weight_bin_data = np.stack(weight_data_list).astype(np.int8)
    weight_bin_data = weight_bin_data.reshape(-1)
    file = open(filename, 'ab')
    for i in range(len(weight_bin_data)):
        file.write(weight_bin_data[i].tobytes())
    file.close()

def main():
    quan_fn = weight_quantize_fn(w_bit=8)
    linear_q = nn.Linear(384, 384)
    linear_q_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=128.)
    linear_k = nn.Linear(384, 384)
    linear_k_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=128.)
    linear_v = nn.Linear(384, 384)
    linear_v_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=128.)

    attn_v_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=4.)

    mlp_projfc = nn.Linear(384, 384)
    mlp_projfc_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=128.)
    mlp_fc0 = nn.Linear(384, 1536)
    mlp_fc0_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=256.)
    mlp_fc1 = nn.Linear(1536, 384)
    mlp_fc1_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=128.)

    model = create_model(
        'spikformer_Q',
        pretrained=False,
        drop_rate=0.,
        drop_path_rate=0.,
        drop_block_rate=None,
        img_size_h=32, img_size_w=32,
        patch_size=4, embed_dims=384, num_heads=12, mlp_ratios=4,
        in_channels=3, num_classes=10, qkv_bias=False,
        depths=4, sr_ratios=1,
        T=4)

    checkpoint_path = 'model_cifar10_withoutbn_q.pth.tar'
    checkpoint = torch.load(checkpoint_path, map_location='cpu')
    new_state_dict = OrderedDict()
    for k, v in checkpoint['state_dict'].items():
        name = k[7:] if k.startswith('module') else k
        new_state_dict[name] = v
    model.load_state_dict(new_state_dict)

    ### ------------------------------------------------ q_linear ------------------------------------------------ ###
    linear_q_weights = new_state_dict['block.0.attn.q_linear.weight']
    linear_q_scale = scale_cal(linear_q_weights)
    weight_linear_q = quan_fn(linear_q_weights).cpu().numpy()

    bias_linear_q = new_state_dict['block.0.attn.q_linear.bias']
    bias_linear_q_scale = scale_cal(bias_linear_q)
    bias_linear_q = quan_fn(bias_linear_q).cpu().numpy()

    quan_weight_linear_q = weight_linear_q * linear_q_scale.cpu().numpy()
    quan_bias_linear_q = 128/16 * bias_linear_q * bias_linear_q_scale.cpu().numpy()
    ### Weights_reshape2Storage(quan_weight_linear_q, '../data4fpga_bin/linear_q_weight.bin')
    ### write_data2coefile_int16('../data4fpga_bin/linear_q_bias.coe', quan_bias_linear_q.astype(np.int16))

    linear_q.weight.data = torch.tensor(quan_weight_linear_q)
    linear_q.bias.data   = torch.tensor(quan_bias_linear_q)
    out_data = read_txt_from_vivado('../data4fpga_bin/embedpatch_out', (384, 8, 8)).reshape(4, 384, -1).swapaxes(-1, -2)  # (4, 64, 384)
    x_for_kqv = torch.tensor(out_data, dtype=torch.float32)
    with torch.no_grad():
        linear_q_out_python = linear_q(x_for_kqv).cpu().numpy()
    linear_q_out_fpga_tmp = read_txt_from_vivado('../data4fpga_bin/attn_linear_q_out', (-1, 16, 16)) # (4, 96, 16, 16)
    linear_q_out_fpga = np.zeros((4, 64, 384))
    for pos_y in range(4):
        for pos_x in range(24):
            linear_q_out_fpga[:, 16*pos_y:16*(pos_y+1), 16*pos_x:16*(pos_x+1)] = linear_q_out_fpga_tmp[:, 24*pos_y + pos_x, :, :]

    diff_linear_q = linear_q_out_fpga - linear_q_out_python
    if np.sum(diff_linear_q) == 0:
        print('linear q \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('linear q \033[4;38;2;200;0;0mfalse\033[0m!')

    ### ------------------------------------------------ k_linear ------------------------------------------------ ###
    linear_k_weights = new_state_dict['block.0.attn.k_linear.weight']
    linear_k_scale = scale_cal(linear_k_weights)
    weight_linear_k = quan_fn(linear_k_weights).cpu().numpy()

    bias_linear_k = new_state_dict['block.0.attn.k_linear.bias']
    bias_linear_k_scale = scale_cal(bias_linear_k)
    bias_linear_k = quan_fn(bias_linear_k).cpu().numpy()

    quan_weight_linear_k = weight_linear_k * linear_k_scale.cpu().numpy()
    quan_bias_linear_k = 128 / 32 * bias_linear_k * bias_linear_k_scale.cpu().numpy()
    ### Weights_reshape2Storage(quan_weight_linear_k, '../data4fpga_bin/linear_k_weight.bin')
    ### write_data2coefile_int16('../data4fpga_bin/linear_k_bias.coe', quan_bias_linear_k.astype(np.int16))

    linear_k.weight.data = torch.tensor(quan_weight_linear_k)
    linear_k.bias.data = torch.tensor(quan_bias_linear_k)

    with torch.no_grad():
        linear_k_out_python = linear_k(x_for_kqv).cpu().numpy()
    linear_k_out_fpga_tmp = read_txt_from_vivado('../data4fpga_bin/attn_linear_k_out', (-1, 16, 16))  # (4, 96, 16, 16)
    linear_k_out_fpga = np.zeros((4, 64, 384))
    for pos_y in range(4):
        for pos_x in range(24):
            linear_k_out_fpga[:, 16 * pos_y:16 * (pos_y + 1), 16 * pos_x:16 * (pos_x + 1)] = linear_k_out_fpga_tmp[:, 24 * pos_y + pos_x, :, :]

    diff_linear_k = linear_k_out_fpga - linear_k_out_python
    if np.sum(diff_linear_k) == 0:
        print('linear k \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('linear k \033[4;38;2;200;0;0mfalse\033[0m!')

    ### ------------------------------------------------ v_linear ------------------------------------------------ ###
    linear_v_weights = new_state_dict['block.0.attn.v_linear.weight']
    linear_v_scale = scale_cal(linear_v_weights)
    weight_linear_v = quan_fn(linear_v_weights).cpu().numpy()

    bias_linear_v = new_state_dict['block.0.attn.v_linear.bias']
    bias_linear_v_scale = scale_cal(bias_linear_v)
    bias_linear_v = quan_fn(bias_linear_v).cpu().numpy()

    quan_weight_linear_v = weight_linear_v * linear_v_scale.cpu().numpy()
    quan_bias_linear_v = 128 / 32 * bias_linear_v * bias_linear_v_scale.cpu().numpy()
    ### Weights_reshape2Storage(quan_weight_linear_v, '../data4fpga_bin/linear_v_weight.bin')
    ### write_data2coefile_int16('../data4fpga_bin/linear_v_bias.coe', quan_bias_linear_v.astype(np.int16))

    linear_v.weight.data = torch.tensor(quan_weight_linear_v)
    linear_v.bias.data = torch.tensor(quan_bias_linear_v)

    with torch.no_grad():
        linear_v_out_python = linear_v(x_for_kqv).cpu().numpy()
    linear_v_out_fpga_tmp = read_txt_from_vivado('../data4fpga_bin/attn_linear_v_out', (-1, 16, 16))  # (4, 96, 16, 16)
    linear_v_out_fpga = np.zeros((4, 64, 384))
    for pos_y in range(4):
        for pos_x in range(24):
            linear_v_out_fpga[:, 16 * pos_y:16 * (pos_y + 1), 16 * pos_x:16 * (pos_x + 1)] = linear_v_out_fpga_tmp[:, 24 * pos_y + pos_x, :, :]

    diff_linear_v = linear_v_out_fpga - linear_v_out_python
    if np.sum(diff_linear_v) == 0:
        print('linear v \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('linear v \033[4;38;2;200;0;0mfalse\033[0m!')

    ### ------------------------------------------------ LIF GROUP ------------------------------------------------ ###
    with torch.no_grad():
        linear_q_out_python = torch.tensor(linear_q_out_python)
        linear_LIF_q_out_python = linear_q_lif(linear_q_out_python).cpu().numpy()
        linear_k_out_python = torch.tensor(linear_k_out_python)
        linear_LIF_k_out_python = linear_k_lif(linear_k_out_python).cpu().numpy()
        linear_v_out_python = torch.tensor(linear_v_out_python)
        linear_LIF_v_out_python = linear_v_lif(linear_v_out_python).cpu().numpy()

    lif_q_out_fpga_tmp = read_txt_from_vivado('../data4fpga_bin/attn_lif_q_out', (-1, 16, 16))  # (4, 96, 16, 16)
    lif_q_out_fpga = np.zeros((4, 64, 384))
    for pos_y in range(4):
        for pos_x in range(24):
            lif_q_out_fpga[:, 16 * pos_y:16 * (pos_y + 1), 16 * pos_x:16 * (pos_x + 1)] = lif_q_out_fpga_tmp[:, 24 * pos_y + pos_x, :, :]

    lif_k_out_fpga_tmp = read_txt_from_vivado('../data4fpga_bin/attn_lif_k_out', (-1, 16, 16))  # (4, 96, 16, 16)
    lif_k_out_fpga = np.zeros((4, 64, 384))
    for pos_y in range(4):
        for pos_x in range(24):
            lif_k_out_fpga[:, 16 * pos_y:16 * (pos_y + 1), 16 * pos_x:16 * (pos_x + 1)] = lif_k_out_fpga_tmp[:, 24 * pos_y + pos_x, :, :]

    lif_v_out_fpga_tmp = read_txt_from_vivado('../data4fpga_bin/attn_lif_v_out', (-1, 16, 16))  # (4, 96, 16, 16)
    lif_v_out_fpga = np.zeros((4, 64, 384))
    for pos_y in range(4):
        for pos_x in range(24):
            lif_v_out_fpga[:, 16 * pos_y:16 * (pos_y + 1), 16 * pos_x:16 * (pos_x + 1)] = lif_v_out_fpga_tmp[:, 24 * pos_y + pos_x, :, :]

    diff_lif_q = linear_LIF_q_out_python - lif_q_out_fpga
    diff_lif_k = linear_LIF_k_out_python - lif_k_out_fpga
    diff_lif_v = linear_LIF_v_out_python - lif_v_out_fpga
    if np.sum(diff_lif_q) == 0 and np.sum(diff_lif_k) == 0 and np.sum(diff_lif_v) == 0:
        print('lif qkv \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('lif qkv \033[4;38;2;200;0;0mfalse\033[0m!')

    Align_lif_q_out_fpga_tmp = read_txt_from_vivado('../data4fpga_bin/align_lif_out', (-1, 16, 32))  # (4, 48, 16, 32)
    Align_lif_q_out_fpga = np.zeros((4, 64, 384))
    for pos_y in range(4):
        for pos_x in range(12):
            Align_lif_q_out_fpga[:, 16 * pos_y : 16 * (pos_y + 1), 32 * pos_x : 32 * (pos_x + 1)] = Align_lif_q_out_fpga_tmp[:, 12 * pos_y + pos_x, :, :]
    diff_Aligndata = Align_lif_q_out_fpga - linear_LIF_q_out_python
    if np.sum(diff_Aligndata) == 0:
        print('Align-lif q \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('Align-lif q \033[4;38;2;200;0;0mfalse\033[0m!')

    ### ------------------------------------------------ Attention ------------------------------------------------ ###
    lif_q_out_fpga_reshape = torch.tensor(lif_q_out_fpga).reshape(4, 64, 12, 384 // 12).permute(0, 2, 1, 3).contiguous()
    lif_k_out_fpga_reshape = torch.tensor(lif_k_out_fpga).reshape(4, 64, 12, 384 // 12).permute(0, 2, 1, 3).contiguous()
    lif_v_out_fpga_reshape = torch.tensor(lif_v_out_fpga).reshape(4, 64, 12, 384 // 12).permute(0, 2, 1, 3).contiguous()

    tmp_attn_data = read_txt_from_vivado('../data4fpga_bin/Calc_attn_out', (-1, 64, 64)).transpose(0, 1, 3, 2)
    attn_data_python = (lif_q_out_fpga_reshape @ lif_k_out_fpga_reshape.transpose(-2, -1)).cpu().numpy()
    diff_attn = tmp_attn_data - attn_data_python
    if np.sum(diff_attn) == 0:
        print('q @ k.transpose calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('q @ k.transpose calc \033[4;38;2;200;0;0mfalse\033[0m!')

    attn_v_out_python = ((torch.tensor(attn_data_python) @ lif_v_out_fpga_reshape).transpose(1, 2).reshape(4, 64, 384).contiguous()).cpu().numpy()
    attn_v_out_fpga = read_txt_from_vivado('../data4fpga_bin/CalcMulti_attnV_out', (384, 64)).transpose(0, 2, 1)
    diff_attn_v = (attn_v_out_fpga - attn_v_out_python)
    if np.sum(diff_attn_v) == 0:
        print('attn @ v calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('attn @ v calc \033[4;38;2;200;0;0mfalse\033[0m!')

    # attn_v_lif
    with torch.no_grad():
        attn_v_out_fpga = torch.tensor(attn_v_out_fpga) # .transpose(1, 2).reshape(4, 64, 384).contiguous()
        lif_attnv_python = attn_v_lif(attn_v_out_fpga).cpu().numpy()
    lif_attnv_out_fpga = read_txt_from_vivado('../data4fpga_bin/lif_CalcMulti_attnV_out', (384, 64))
    lif_attnv_out_fpga = torch.tensor(lif_attnv_out_fpga).transpose(1, 2).contiguous().cpu().numpy()
    diff_lif_attnv = lif_attnv_out_fpga - lif_attnv_python
    if np.sum(diff_lif_attnv) == 0:
        print('lif attn @ v calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('lif attn @ v calc \033[4;38;2;200;0;0mfalse\033[0m!')

    ### ------------------------------------------------ MLP ------------------------------------------------ ###
    ################################ 'block.0.attn.proj_linear.weight'  'block.0.attn.proj_linear.bias'
    attn_proj_linear_weight = new_state_dict['block.0.attn.proj_linear.weight']
    attn_proj_linear_scale = scale_cal(attn_proj_linear_weight)
    attn_proj_linear_weight = quan_fn(attn_proj_linear_weight).cpu().numpy()
    attn_proj_linear_bias = new_state_dict['block.0.attn.proj_linear.bias']
    bias_attn_proj_linear_scale = scale_cal(attn_proj_linear_bias)
    attn_proj_linear_bias = quan_fn(attn_proj_linear_bias).cpu().numpy()

    quan_weight_attn_proj_linear = attn_proj_linear_weight * attn_proj_linear_scale.cpu().numpy()
    quan_bias_attn_proj_linear = 128 / 32 * attn_proj_linear_bias * bias_attn_proj_linear_scale.cpu().numpy()

        ## -----> store to .bin file
    rshp_attn_proj_linear_weight = quan_weight_attn_proj_linear.reshape(384, 8, 48)
    rshp_attn_proj_linear_weight_bin_no1 = rshp_attn_proj_linear_weight[:, :, :16].reshape(-1, 128)
    rshp_attn_proj_linear_weight_bin_no2 = rshp_attn_proj_linear_weight[:, :, 16:32].reshape(-1, 128)
    rshp_attn_proj_linear_weight_bin_no3 = rshp_attn_proj_linear_weight[:, :, 32:48].reshape(-1, 128)
        ## end -----> store to .bin file

    ############################### 'block.0.mlp.fc1_linear.weight'  'block.0.mlp.fc1_linear.bias'
    attn_mlp_fc1_weight = new_state_dict['block.0.mlp.fc1_linear.weight']
    attn_mlp_fc1_scale = scale_cal(attn_mlp_fc1_weight)
    attn_mlp_fc1_weight = quan_fn(attn_mlp_fc1_weight).cpu().numpy()
    attn_mlp_fc1_bias = new_state_dict['block.0.mlp.fc1_linear.bias']
    bias_attn_mlp_fc1_scale = scale_cal(attn_mlp_fc1_bias)
    attn_mlp_fc1_bias = quan_fn(attn_mlp_fc1_bias).cpu().numpy()

    quan_weight_attn_mlp_fc1 = attn_mlp_fc1_weight * attn_mlp_fc1_scale.cpu().numpy()
    quan_bias_attn_mlp_fc1 = 256 / 32 * attn_mlp_fc1_bias * bias_attn_mlp_fc1_scale.cpu().numpy()

        ## -----> store to .bin file
    rshp_attn_mlp_fc1_weight = quan_weight_attn_mlp_fc1.reshape(1536, 8, 48)
    attn_mlp_fc1_weight_bin_no1 = rshp_attn_mlp_fc1_weight[:, :, :16].reshape(-1, 128)
    attn_mlp_fc1_weight_bin_no2 = rshp_attn_mlp_fc1_weight[:, :, 16:32].reshape(-1, 128)
    attn_mlp_fc1_weight_bin_no3 = rshp_attn_mlp_fc1_weight[:, :, 32:48].reshape(-1, 128)
        ## end -----> store to .bin file

    ################################ 'block.0.mlp.fc2_linear.weight'  'block.0.mlp.fc2_linear.bias'
    attn_mlp_fc2_weight = new_state_dict['block.0.mlp.fc2_linear.weight']
    attn_mlp_fc2_scale = scale_cal(attn_mlp_fc2_weight)
    attn_mlp_fc2_weight = quan_fn(attn_mlp_fc2_weight).cpu().numpy()

    attn_mlp_fc2_bias = new_state_dict['block.0.mlp.fc2_linear.bias']
    bias_attn_mlp_fc2_scale = scale_cal(attn_mlp_fc2_bias)
    attn_mlp_fc2_bias = quan_fn(attn_mlp_fc2_bias).cpu().numpy()

    quan_weight_attn_mlp_fc2 = attn_mlp_fc2_weight * attn_mlp_fc2_scale.cpu().numpy()
    quan_bias_attn_mlp_fc2 = 128 / 32 * attn_mlp_fc2_bias * bias_attn_mlp_fc2_scale.cpu().numpy()

        ## -----> store to .bin file
    rshp_attn_mlp_fc2_weight = quan_weight_attn_mlp_fc2.reshape(384, -1, 48)
    attn_mlp_fc2_weight_bin_no1 = rshp_attn_mlp_fc2_weight[:, :, :16].reshape(384, -1)
    attn_mlp_fc2_weight_bin_no2 = rshp_attn_mlp_fc2_weight[:, :, 16:32].reshape(384, -1)
    attn_mlp_fc2_weight_bin_no3 = rshp_attn_mlp_fc2_weight[:, :, 32:48].reshape(384, -1)
        ## end -----> store to .bin file
    mlp_bias = np.concatenate([quan_bias_attn_proj_linear, quan_bias_attn_mlp_fc1, quan_bias_attn_mlp_fc2])
    ### write_data2coefile_int16('../data4fpga_bin/mlp_bias.coe', mlp_bias.astype(np.int16))

    ### write -> .bin ###
    ### Weights_reshape2Storage(rshp_attn_proj_linear_weight_bin_no1, '../data4fpga_bin/linear_q_weight.bin')
    ### Weights_reshape2Storage(attn_mlp_fc1_weight_bin_no1, '../data4fpga_bin/linear_q_weight.bin')
    ### Weights_reshape2Storage(attn_mlp_fc2_weight_bin_no1, '../data4fpga_bin/linear_q_weight.bin')
    ###
    ### Weights_reshape2Storage(rshp_attn_proj_linear_weight_bin_no2, '../data4fpga_bin/linear_k_weight.bin')
    ### Weights_reshape2Storage(attn_mlp_fc1_weight_bin_no2, '../data4fpga_bin/linear_k_weight.bin')
    ### Weights_reshape2Storage(attn_mlp_fc2_weight_bin_no2, '../data4fpga_bin/linear_k_weight.bin')
    ###
    ### Weights_reshape2Storage(rshp_attn_proj_linear_weight_bin_no3, '../data4fpga_bin/linear_v_weight.bin')
    ### Weights_reshape2Storage(attn_mlp_fc1_weight_bin_no3, '../data4fpga_bin/linear_v_weight.bin')
    ### Weights_reshape2Storage(attn_mlp_fc2_weight_bin_no3, '../data4fpga_bin/linear_v_weight.bin')

    ### bin_file_data = np.fromfile('../data4fpga_bin/linear_q_weight.bin', dtype=np.int8)

    # ----------------------- MLP Calc Part ----------------------- #
    mlp_projfc.weight.data = torch.tensor(quan_weight_attn_proj_linear)
    mlp_projfc.bias.data   = torch.tensor(quan_bias_attn_proj_linear)
    mlp_fc0.weight.data = torch.tensor(quan_weight_attn_mlp_fc1)
    mlp_fc0.bias.data   = torch.tensor(quan_bias_attn_mlp_fc1)
    mlp_fc1.weight.data = torch.tensor(quan_weight_attn_mlp_fc2)
    mlp_fc1.bias.data   = torch.tensor(quan_bias_attn_mlp_fc2)

    with torch.no_grad():
        lif_attnv_out_fpga = torch.tensor(lif_attnv_out_fpga, dtype=torch.float32)  # 4, 64, 384
        mlp_projfc_out_python = mlp_projfc(lif_attnv_out_fpga).cpu().numpy()

    mlp_projfc_out_fpga = read_txt_from_vivado('../data4fpga_bin/before_act_mlp_projfc', (-1, 384, 16))  # 4, 4, 384, 16
    mlp_projfc_out_fpga = mlp_projfc_out_fpga.transpose(0, 1, 3, 2).reshape(4, -1, 384)
    mlp_projfc_lif_out_fpga = read_txt_from_vivado('../data4fpga_bin/mlp_projfc_out', (-1, 384, 16)).transpose(0, 1, 3, 2).reshape(4, -1, 384)
    diff_projfc = mlp_projfc_out_fpga - mlp_projfc_out_python
    if np.sum(diff_projfc) == 0:
        print('Proj_fc calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('Proj_fc calc \033[4;38;2;200;0;0mfalse\033[0m!')

    with torch.no_grad():
        mlp_projfc_out_python = torch.tensor(mlp_projfc_out_python).unsqueeze(1)
        lif_mlp_projfc_out_python = mlp_projfc_lif(mlp_projfc_out_python).squeeze(dim=1).cpu().numpy() # 4, 64, 384
        ts_lif_mlp_projfc_out_python = torch.tensor(lif_mlp_projfc_out_python) + x_for_kqv
        np_lif_mlp_projfc_out_python = ts_lif_mlp_projfc_out_python.cpu().numpy()
        mlp_fc0_out_python = mlp_fc0(ts_lif_mlp_projfc_out_python).cpu().numpy()

    lif_mlp_projfc_out_fpga = read_txt_from_vivado('../data4fpga_bin/mlp_projfc_out', (-1, 384, 16)).transpose(0, 1, 3, 2).reshape(4, -1, 384)
    diff_projfc_lif = lif_mlp_projfc_out_fpga - lif_mlp_projfc_out_python
    if np.sum(diff_projfc_lif) == 0:
        print('lif Proj_fc calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('lif Proj_fc calc \033[4;38;2;200;0;0mfalse\033[0m!')

    mlp_fc0_out_fpga = read_txt_from_vivado('../data4fpga_bin/before_act_mlp_fc0', (-1, 1536, 16)).transpose(0, 1, 3, 2).reshape(4, -1, 1536)
    diff_mlp_fc0 = mlp_fc0_out_fpga - mlp_fc0_out_python
    if np.sum(diff_mlp_fc0) == 0:
        print('mlp fc0 calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('mlp fc0 calc \033[4;38;2;200;0;0mfalse\033[0m!')

    with torch.no_grad():
        ts_mlp_fc0_out_python = torch.tensor(mlp_fc0_out_python).unsqueeze(1)
        lif_mlp_fc0_out_python = mlp_fc0_lif(ts_mlp_fc0_out_python).squeeze(dim=1).cpu().numpy()
        ts_lif_mlp_fc0_out_python = torch.tensor(lif_mlp_fc0_out_python)
        mlp_fc1_out_python = mlp_fc1(ts_lif_mlp_fc0_out_python).cpu().numpy()
    lif_mlp_fc0_out_fpga = read_txt_from_vivado('../data4fpga_bin/mlp_fc0_out', (-1, 1536, 16)).transpose(0, 1, 3, 2).reshape(4, -1, 1536)
    diff_lif_mlp_fc0 = lif_mlp_fc0_out_fpga - lif_mlp_fc0_out_python
    if np.sum(diff_lif_mlp_fc0) == 0:
        print('lif mlp fc0 calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('lif mlp fc0 calc \033[4;38;2;200;0;0mfalse\033[0m!')

    mlp_fc1_out_fpga = read_txt_from_vivado('../data4fpga_bin/before_act_mlp_fc1', (-1, 384, 16)).transpose(0, 1, 3, 2).reshape(4, -1, 384)
    diff_mlp_fc1 = mlp_fc1_out_fpga - mlp_fc1_out_python
    if np.sum(diff_mlp_fc1) == 0:
        print('mlp fc1 calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('mlp fc1 calc \033[4;38;2;200;0;0mfalse\033[0m!')

    with torch.no_grad():
        ts_mlp_fc1_out_python = torch.tensor(mlp_fc1_out_python).unsqueeze(1)
        lif_mlp_fc1_out_python = mlp_fc1_lif(ts_mlp_fc1_out_python).squeeze(dim=1).cpu().numpy()
    lif_mlp_fc1_out_fpga = read_txt_from_vivado('../data4fpga_bin/mlp_fc1_out', (-1, 384, 16)).transpose(0, 1, 3, 2).reshape(4, -1, 384)
    diff_lif_mlp_fc1 = lif_mlp_fc1_out_fpga - lif_mlp_fc1_out_python
    if np.sum(diff_lif_mlp_fc1) == 0:
        print('lif mlp fc1 calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('lif mlp fc1 calc \033[4;38;2;200;0;0mfalse\033[0m!')

    input_add_projfc_out_fpga = read_txt_from_vivado('../data4fpga_bin/input_add_projfc', (384, 64)).transpose(0, 2, 1)
    diff_input_add_projfc = input_add_projfc_out_fpga - np_lif_mlp_projfc_out_python
    if np.sum(diff_input_add_projfc) == 0:
        print('input + projfc calc \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('input + projfc calc \033[4;38;2;200;0;0mfalse\033[0m!')
    print(1)

if __name__ == '__main__':
    main()
