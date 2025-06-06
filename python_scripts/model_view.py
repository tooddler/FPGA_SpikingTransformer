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

def write_data2coefile(filename: str, data):
    """Write data (must be int8) to a coefficient file."""
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


def rgb888_to_rgb565(r, g, b):
    r_matrix = r.astype(np.int16) + 128
    g_matrix = g.astype(np.int16) + 128
    b_matrix = b.astype(np.int16) + 128
    red_5   = (r_matrix >> 3) & 0x1F  # 保留低 5 位
    green_6 = (g_matrix >> 2) & 0x3F  # 保留低 6 位
    blue_5  = (b_matrix >> 3) & 0x1F  # 保留低 5 位
    rgb565 = (red_5 << 11) | (green_6 << 5) | blue_5
    return rgb565.astype(np.uint16)

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

def main():
    quan_fn = weight_quantize_fn(w_bit=8)

    conv = nn.Conv2d(in_channels=3, out_channels=48, kernel_size=(3, 3), padding=1, bias=True)
    sps_conv = nn.Conv2d(in_channels=48, out_channels=96, kernel_size=(3, 3), padding=1, bias=True)
    sps_conv2 = nn.Conv2d(in_channels=96, out_channels=192, kernel_size=(3, 3), padding=1, bias=True)
    sps_maxpool = torch.nn.MaxPool2d(kernel_size=3, stride=2, padding=1, dilation=1, ceil_mode=False)
    sps_conv3 = nn.Conv2d(in_channels=192, out_channels=384, kernel_size=(3, 3), padding=1, bias=True)
    sps_conv4 = nn.Conv2d(in_channels=384, out_channels=384, kernel_size=(3, 3), padding=1, bias=True)

    proj_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=2048.)
    sps_proj_lif1 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=64.)
    sps_proj_lif2 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=128.)
    sps_proj_lif3 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=256.)
    sps_proj_lif4 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch', v_threshold=128.)

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
        T=4)        # fixme : depths = 1

    img = torch.tensor(np.load('data_bs128.npy'))

    max = 0
    data_list = []
    for n in range(1): # img.shape[0]
        if scale_cal(img[n]) > max:
            max = scale_cal(img[n])
        r = fixed_scale_weight_quantize_fn(img[n][0]) * 64
        g = fixed_scale_weight_quantize_fn(img[n][1]) * 64
        b = fixed_scale_weight_quantize_fn(img[n][2]) * 64

        quantized_img4test = np.stack([r, g, b])

        for col in range(img.shape[2]):
            for row in range(img.shape[3]):
                data_list.append(r[col][row])
                data_list.append(g[col][row])
                data_list.append(b[col][row])
    weight_bin_data = np.stack(data_list).astype(np.int8)
    weight_bin_data = weight_bin_data.reshape(-1)
    file = open('../data4fpga_bin/img_bin.bin', 'wb')
    for i in range(len(weight_bin_data)):
        file.write(weight_bin_data[i].tobytes())
    file.close()

    # ------>>>>>>> check img in data
    # # padding
    weight_bin_data = weight_bin_data.reshape(32, 32*3)
    weight_bin_data_padding = np.zeros((34, 34*3))
    weight_bin_data_padding[1:33, 1*3:33*3] = weight_bin_data

    img_fpga_out = []
    with open('../data4fpga_bin/data_img_out.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                img_fpga_out.append(float(line.strip()))
    f.close()
    img_fpga_out = np.stack(img_fpga_out)
    diff = (img_fpga_out - weight_bin_data_padding.reshape(-1)).sum()

    checkpoint_path = 'model_cifar10_withoutbn_q.pth.tar'
    # checkpoint_path = 'model_best.pth.tar'
    checkpoint = torch.load(checkpoint_path, map_location='cpu')
    new_state_dict = OrderedDict()
    for k, v in checkpoint['state_dict'].items():
        name = k[7:] if k.startswith('module') else k
        new_state_dict[name] = v
    model.load_state_dict(new_state_dict)

    weight_layer1 = new_state_dict['patch_embed.proj_conv.weight']
    weight_layer1_scale = scale_cal(weight_layer1)
    weight_layer1 = quan_fn(weight_layer1).cpu().numpy()

    bias_layer1   = new_state_dict['patch_embed.proj_conv.bias']
    bias_layer1_scale = scale_cal(bias_layer1)
    bias_layer1   = quan_fn(bias_layer1).cpu().numpy()

    quan_weight_layer1 =  weight_layer1 * weight_layer1_scale.cpu().numpy()
    quan_bias_layer1   =  bias_layer1 * bias_layer1_scale.cpu().numpy()

    ##### save_data_to_binfile(quan_weight_layer1)

    # quantized_img4test_numpy = quantized_img4test
    quantized_img4test = torch.tensor(quantized_img4test)
    conv.weight.data = torch.tensor(quan_weight_layer1)
    conv.bias.data   = torch.tensor(quan_bias_layer1 * 32)

    with torch.no_grad():
        conv_fpga_out111 = conv(quantized_img4test).cpu().numpy()

    conv_fpga_out = []
    with open('../data4fpga_bin/conv1_out.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                conv_fpga_out.append(float(line.strip()))
    f.close()

    conv_fpga_out = np.stack(conv_fpga_out).reshape(48, 32, 32)
    #
    conv_python_out = conv_fpga_out111 #[0] # .reshape(1024)
    #
    diff_conv = (conv_python_out - conv_fpga_out).sum()

    # save_data_to_binfile(quan_weight_layer1)
    # write_data2coefile('../data4fpga_bin/conv1_bias.coe', quan_bias_layer1.astype(np.int8))
    lif_fpga_out_t0 = []
    lif_fpga_out_t1 = []
    lif_fpga_out_t2 = []
    lif_fpga_out_t3 = []
    with open('../data4fpga_bin/spiking0_out_out.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t0.append(float(line.strip()))
    f.close()
    lif_fpga_out_t0 = np.stack(lif_fpga_out_t0).reshape(48, 32, 32)
    with open('../data4fpga_bin/spiking1_out_out.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t1.append(float(line.strip()))
    f.close()
    lif_fpga_out_t1 = np.stack(lif_fpga_out_t1).reshape(48, 32, 32)
    with open('../data4fpga_bin/spiking2_out_out.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t2.append(float(line.strip()))
    f.close()
    lif_fpga_out_t2 = np.stack(lif_fpga_out_t2).reshape(48, 32, 32)
    with open('../data4fpga_bin/spiking3_out_out.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                lif_fpga_out_t3.append(float(line.strip()))
    f.close()
    lif_fpga_out_t3 = np.stack(lif_fpga_out_t3).reshape(48, 32, 32)
    lif_fpga_out = np.stack([lif_fpga_out_t0, lif_fpga_out_t1, lif_fpga_out_t2, lif_fpga_out_t3])
    conv_python_out = (torch.tensor(conv_python_out).unsqueeze(0)).repeat(4, 1, 1, 1, 1)
    lif_python_out = proj_lif(conv_python_out).squeeze(dim=1).cpu().numpy()

    diff_lif = lif_python_out - lif_fpga_out
    if np.sum(diff_lif) == 0:
        print('conv1 lif \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('conv1 lif \033[4;38;2;200;0;0mfalse\033[0m!')

    ##### spiking layer1 #####
    Spiking_Data = lif_fpga_out[:, :]
    sps_weight_layer1 = new_state_dict['patch_embed.proj_conv1.weight']
    sps_weight_layer1_scale = scale_cal(sps_weight_layer1)
    sps_weight_layer1 = quan_fn(sps_weight_layer1).cpu().numpy()

    sps_bias_layer1   = new_state_dict['patch_embed.proj_conv1.bias']
    sps_bias_layer1_scale = scale_cal(sps_bias_layer1)
    sps_bias_layer1   = quan_fn(sps_bias_layer1).cpu().numpy()
    sps_quan_weight_layer1 = sps_weight_layer1 * sps_weight_layer1_scale.cpu().numpy()
    sps_quan_bias_layer1 = sps_bias_layer1 * sps_bias_layer1_scale.cpu().numpy()

    weight_tmp = sps_quan_weight_layer1 #[0, :]
    sps_conv.weight.data = torch.tensor(weight_tmp) #.unsqueeze(dim=0)
    sps_conv.bias.data   = torch.tensor(sps_quan_bias_layer1)

    # write_data2coefile('../data4fpga_bin/sps_conv1_bias.coe', sps_quan_bias_layer1.astype(np.int8))
    # test_data = torch.ones(4, 48, 32, 32)
    with torch.no_grad():
        sps_conv1_out_python = sps_conv(torch.tensor(Spiking_Data, dtype=torch.float)).cpu().numpy()

    ## read data from fpga sim ###
    sps_conv1_fpga_out_t0 = []
    sps_conv1_fpga_out_t1 = []
    sps_conv1_fpga_out_t2 = []
    sps_conv1_fpga_out_t3 = []
    with open('../data4fpga_bin/sps_conv1_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv1_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_conv1_fpga_out_t0 = np.stack(sps_conv1_fpga_out_t0).reshape(96, 32, 32)
    with open('../data4fpga_bin/sps_conv1_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv1_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_conv1_fpga_out_t1 = np.stack(sps_conv1_fpga_out_t1).reshape(96, 32, 32)
    with open('../data4fpga_bin/sps_conv1_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv1_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_conv1_fpga_out_t2 = np.stack(sps_conv1_fpga_out_t2).reshape(96, 32, 32)
    with open('../data4fpga_bin/sps_conv1_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv1_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_conv1_fpga_out_t3 = np.stack(sps_conv1_fpga_out_t3).reshape(96, 32, 32)
    sps_conv1_out_fpga = np.stack([sps_conv1_fpga_out_t0, sps_conv1_fpga_out_t1, sps_conv1_fpga_out_t2, sps_conv1_fpga_out_t3])
    sps_conv1_diff = sps_conv1_out_fpga - sps_conv1_out_python

    ## read spikes data from fpga sim ###
    sps_conv1_out_python = torch.tensor(sps_conv1_out_python).unsqueeze(1)
    sps_lif1_out_python = sps_proj_lif1(sps_conv1_out_python).squeeze(dim=1).cpu().numpy()

    sps_lif1_fpga_out_t0 = []
    sps_lif1_fpga_out_t1 = []
    sps_lif1_fpga_out_t2 = []
    sps_lif1_fpga_out_t3 = []
    with open('../data4fpga_bin/sps_lif1_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif1_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_lif1_fpga_out_t0 = np.stack(sps_lif1_fpga_out_t0).reshape(96, 32, 32)
    with open('../data4fpga_bin/sps_lif1_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif1_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_lif1_fpga_out_t1 = np.stack(sps_lif1_fpga_out_t1).reshape(96, 32, 32)
    with open('../data4fpga_bin/sps_lif1_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif1_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_lif1_fpga_out_t2 = np.stack(sps_lif1_fpga_out_t2).reshape(96, 32, 32)
    with open('../data4fpga_bin/sps_lif1_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif1_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_lif1_fpga_out_t3 = np.stack(sps_lif1_fpga_out_t3).reshape(96, 32, 32)
    sps_lif1_out_fpga = np.stack([sps_lif1_fpga_out_t0, sps_lif1_fpga_out_t1, sps_lif1_fpga_out_t2, sps_lif1_fpga_out_t3])
    sps_diff_lif1 = sps_lif1_out_fpga - sps_lif1_out_python
    if np.sum(sps_diff_lif1) == 0:
        print('sps lif1 \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('sps lif1 \033[4;38;2;200;0;0mfalse\033[0m!')

    ##### end spiking layer1 #####

    ##### spiking layer2 #####
    Spiking_Data1 = sps_lif1_out_fpga[:, :]
    sps_weight_layer2 = new_state_dict['patch_embed.proj_conv2.weight']
    sps_weight_layer2_scale = scale_cal(sps_weight_layer2)
    sps_weight_layer2 = quan_fn(sps_weight_layer2).cpu().numpy()

    sps_bias_layer2   = new_state_dict['patch_embed.proj_conv2.bias']
    sps_bias_layer2_scale = scale_cal(sps_bias_layer2)
    sps_bias_layer2   = quan_fn(sps_bias_layer2).cpu().numpy()
    sps_quan_weight_layer2 = sps_weight_layer2 * sps_weight_layer2_scale.cpu().numpy()
    sps_quan_bias_layer2 = 4 * sps_bias_layer2 * sps_bias_layer2_scale.cpu().numpy() # 4 *

    #### save_data_to_binfile(sps_quan_weight_layer2)
    sps_conv2.weight.data = torch.tensor(sps_quan_weight_layer2)  # .unsqueeze(dim=0)
    sps_conv2.bias.data = torch.tensor(sps_quan_bias_layer2)

    # bias_data = np.append(sps_quan_bias_layer1, sps_quan_bias_layer2)
    # write_data2coefile('../data4fpga_bin/sps_conv_bias.coe', bias_data.astype(np.int8))

    with torch.no_grad():
        sps_conv2_out_python = sps_conv2(torch.tensor(Spiking_Data1, dtype=torch.float)).cpu().numpy()

    sps_conv2_fpga_out_t0 = []
    sps_conv2_fpga_out_t1 = []
    sps_conv2_fpga_out_t2 = []
    sps_conv2_fpga_out_t3 = []
    with open('../data4fpga_bin/sps_conv2_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv2_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_conv2_fpga_out_t0 = np.stack(sps_conv2_fpga_out_t0).reshape(192, 32, 32)
    with open('../data4fpga_bin/sps_conv2_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv2_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_conv2_fpga_out_t1 = np.stack(sps_conv2_fpga_out_t1).reshape(192, 32, 32)
    with open('../data4fpga_bin/sps_conv2_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv2_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_conv2_fpga_out_t2 = np.stack(sps_conv2_fpga_out_t2).reshape(192, 32, 32)
    with open('../data4fpga_bin/sps_conv2_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv2_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_conv2_fpga_out_t3 = np.stack(sps_conv2_fpga_out_t3).reshape(192, 32, 32)
    sps_conv2_out_fpga = np.stack([sps_conv2_fpga_out_t0, sps_conv2_fpga_out_t1, sps_conv2_fpga_out_t2, sps_conv2_fpga_out_t3])
    sps_conv2_diff = sps_conv2_out_fpga - sps_conv2_out_python

    sps_conv2_out_python = torch.tensor(sps_conv2_out_python).unsqueeze(1)
    sps_lif2_out_python = sps_proj_lif2(sps_conv2_out_python).squeeze(dim=1).cpu().numpy()

    sps_lif2_fpga_out_t0 = []
    sps_lif2_fpga_out_t1 = []
    sps_lif2_fpga_out_t2 = []
    sps_lif2_fpga_out_t3 = []
    with open('../data4fpga_bin/sps_lif2_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif2_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_lif2_fpga_out_t0 = np.stack(sps_lif2_fpga_out_t0).reshape(192, 32, 32)
    with open('../data4fpga_bin/sps_lif2_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif2_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_lif2_fpga_out_t1 = np.stack(sps_lif2_fpga_out_t1).reshape(192, 32, 32)
    with open('../data4fpga_bin/sps_lif2_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif2_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_lif2_fpga_out_t2 = np.stack(sps_lif2_fpga_out_t2).reshape(192, 32, 32)
    with open('../data4fpga_bin/sps_lif2_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif2_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_lif2_fpga_out_t3 = np.stack(sps_lif2_fpga_out_t3).reshape(192, 32, 32)
    sps_lif2_out_fpga = np.stack([sps_lif2_fpga_out_t0, sps_lif2_fpga_out_t1, sps_lif2_fpga_out_t2, sps_lif2_fpga_out_t3])

    sps_diff_lif2 = sps_lif2_out_fpga - sps_lif2_out_python
    if np.sum(sps_diff_lif2) == 0:
        print('sps lif2 \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('sps lif2 \033[4;38;2;200;0;0mfalse\033[0m!')

    ##### end spiking layer2 #####

    ##### spiking maxpool1 #####
    sps_lif2_out_fpga = torch.tensor(sps_lif2_out_fpga)
    with torch.no_grad():
        sps_maxpool1_python_out = sps_maxpool(sps_lif2_out_fpga).cpu().numpy()

    sps_maxpool1_fpga_out_t0 = []
    sps_maxpool1_fpga_out_t1 = []
    sps_maxpool1_fpga_out_t2 = []
    sps_maxpool1_fpga_out_t3 = []

    with open('../data4fpga_bin/sps_maxpool1_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool1_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_maxpool1_fpga_out_t0 = np.stack(sps_maxpool1_fpga_out_t0).reshape(192, 16, 16)
    with open('../data4fpga_bin/sps_maxpool1_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool1_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_maxpool1_fpga_out_t1 = np.stack(sps_maxpool1_fpga_out_t1).reshape(192, 16, 16)
    with open('../data4fpga_bin/sps_maxpool1_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool1_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_maxpool1_fpga_out_t2 = np.stack(sps_maxpool1_fpga_out_t2).reshape(192, 16, 16)
    with open('../data4fpga_bin/sps_maxpool1_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool1_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_maxpool1_fpga_out_t3 = np.stack(sps_maxpool1_fpga_out_t3).reshape(192, 16, 16)
    sps_maxpool1_out_fpga = np.stack([sps_maxpool1_fpga_out_t0, sps_maxpool1_fpga_out_t1, sps_maxpool1_fpga_out_t2, sps_maxpool1_fpga_out_t3])

    sps_maxpool1_diff = sps_maxpool1_out_fpga - sps_maxpool1_python_out
    if np.sum(sps_maxpool1_diff) == 0:
        print('sps maxpool1 \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('sps maxpool1 \033[4;38;2;200;0;0mfalse\033[0m!')

    ##### end spiking maxpool1 #####

    ##### spiking layer3 #####
    Spiking_Data3 = sps_maxpool1_out_fpga[:, :]
    sps_weight_layer3 = new_state_dict['patch_embed.proj_conv3.weight']
    sps_weight_layer3_scale = scale_cal(sps_weight_layer3)
    sps_weight_layer3 = quan_fn(sps_weight_layer3).cpu().numpy()

    sps_bias_layer3 = new_state_dict['patch_embed.proj_conv3.bias']
    sps_bias_layer3_scale = scale_cal(sps_bias_layer3)
    sps_bias_layer3 = quan_fn(sps_bias_layer3).cpu().numpy()
    sps_quan_weight_layer3 = sps_weight_layer3 * sps_weight_layer3_scale.cpu().numpy()
    sps_quan_bias_layer3 = 8 * sps_bias_layer3 * sps_bias_layer3_scale.cpu().numpy() # 8 *

    ######## save_data_to_binfile(sps_quan_weight_layer3)
    sps_conv3.weight.data = torch.tensor(sps_quan_weight_layer3)
    sps_conv3.bias.data = torch.tensor(sps_quan_bias_layer3)

    with torch.no_grad():
        sps_conv3_out_python = sps_conv3(torch.tensor(Spiking_Data3, dtype=torch.float)).cpu().numpy()

    sps_conv3_fpga_out_t0 = []
    sps_conv3_fpga_out_t1 = []
    sps_conv3_fpga_out_t2 = []
    sps_conv3_fpga_out_t3 = []

    with open('../data4fpga_bin/sps_conv3_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv3_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_conv3_fpga_out_t0 = np.stack(sps_conv3_fpga_out_t0).reshape(384, 16, 16)
    with open('../data4fpga_bin/sps_conv3_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv3_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_conv3_fpga_out_t1 = np.stack(sps_conv3_fpga_out_t1).reshape(384, 16, 16)
    with open('../data4fpga_bin/sps_conv3_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv3_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_conv3_fpga_out_t2 = np.stack(sps_conv3_fpga_out_t2).reshape(384, 16, 16)
    with open('../data4fpga_bin/sps_conv3_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv3_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_conv3_fpga_out_t3 = np.stack(sps_conv3_fpga_out_t3).reshape(384, 16, 16)
    sps_conv3_out_fpga = np.stack([sps_conv3_fpga_out_t0, sps_conv3_fpga_out_t1, sps_conv3_fpga_out_t2, sps_conv3_fpga_out_t3])
    sps_conv3_diff = sps_conv3_out_fpga - sps_conv3_out_python

    sps_conv3_out_python = torch.tensor(sps_conv3_out_python).unsqueeze(1)
    sps_lif3_out_python = sps_proj_lif3(sps_conv3_out_python).squeeze(dim=1).cpu().numpy()

    # bias_data = np.append(sps_quan_bias_layer1, sps_quan_bias_layer2/4)
    # bias_data = np.append(bias_data, sps_quan_bias_layer3/8)
    # write_data2coefile('../data4fpga_bin/sps_conv_bias.coe', bias_data.astype(np.int8))

    sps_lif3_fpga_out_t0 = []
    sps_lif3_fpga_out_t1 = []
    sps_lif3_fpga_out_t2 = []
    sps_lif3_fpga_out_t3 = []
    with open('../data4fpga_bin/sps_lif3_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif3_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_lif3_fpga_out_t0 = np.stack(sps_lif3_fpga_out_t0).reshape(384, 16, 16)
    with open('../data4fpga_bin/sps_lif3_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif3_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_lif3_fpga_out_t1 = np.stack(sps_lif3_fpga_out_t1).reshape(384, 16, 16)
    with open('../data4fpga_bin/sps_lif3_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif3_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_lif3_fpga_out_t2 = np.stack(sps_lif3_fpga_out_t2).reshape(384, 16, 16)
    with open('../data4fpga_bin/sps_lif3_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif3_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_lif3_fpga_out_t3 = np.stack(sps_lif3_fpga_out_t3).reshape(384, 16, 16)
    sps_lif3_out_fpga = np.stack([sps_lif3_fpga_out_t0, sps_lif3_fpga_out_t1, sps_lif3_fpga_out_t2, sps_lif3_fpga_out_t3])
    sps_lif3_diff = sps_lif3_out_fpga - sps_lif3_out_python
    if np.sum(sps_lif3_diff) == 0:
        print('sps lif3 \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('sps lif3 \033[4;38;2;200;0;0mfalse\033[0m!')

    ##### end spiking layer3 #####

    ##### spiking maxpool2 #####
    sps_lif3_out_fpga = torch.tensor(sps_lif3_out_fpga)
    with torch.no_grad():
        sps_maxpool2_python_out = sps_maxpool(sps_lif3_out_fpga).cpu().numpy()

    sps_maxpool2_fpga_out_t0 = []
    sps_maxpool2_fpga_out_t1 = []
    sps_maxpool2_fpga_out_t2 = []
    sps_maxpool2_fpga_out_t3 = []

    with open('../data4fpga_bin/sps_maxpool2_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool2_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_maxpool2_fpga_out_t0 = np.stack(sps_maxpool2_fpga_out_t0).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_maxpool2_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool2_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_maxpool2_fpga_out_t1 = np.stack(sps_maxpool2_fpga_out_t1).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_maxpool2_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool2_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_maxpool2_fpga_out_t2 = np.stack(sps_maxpool2_fpga_out_t2).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_maxpool2_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_maxpool2_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_maxpool2_fpga_out_t3 = np.stack(sps_maxpool2_fpga_out_t3).reshape(384, 8, 8)
    sps_maxpool2_out_fpga = np.stack([sps_maxpool2_fpga_out_t0, sps_maxpool2_fpga_out_t1, sps_maxpool2_fpga_out_t2, sps_maxpool2_fpga_out_t3])

    sps_maxpool2_diff = sps_maxpool2_out_fpga - sps_maxpool2_python_out
    if np.sum(sps_maxpool2_diff) == 0:
        print('sps maxpool2 \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('sps maxpool2 \033[4;38;2;200;0;0mfalse\033[0m!')

    ##### end spiking maxpool2 #####

    ##### spiking rpe-conv #####
    Spiking_Data4 = sps_maxpool2_out_fpga[:, :]
    sps_weight_layer4 = new_state_dict['patch_embed.rpe_conv.weight']
    sps_weight_layer4_scale = scale_cal(sps_weight_layer4)
    sps_weight_layer4 = quan_fn(sps_weight_layer4).cpu().numpy()

    sps_bias_layer4 = new_state_dict['patch_embed.rpe_conv.bias']
    sps_bias_layer4_scale = scale_cal(sps_bias_layer4)
    sps_bias_layer4 = quan_fn(sps_bias_layer4).cpu().numpy()
    sps_quan_weight_layer4 = sps_weight_layer4 * sps_weight_layer4_scale.cpu().numpy()
    sps_quan_bias_layer4 = 4 * sps_bias_layer4 * sps_bias_layer4_scale.cpu().numpy()

    ######## save_data_to_binfile(sps_quan_weight_layer4)
    # bias_data = np.append(sps_quan_bias_layer1, sps_quan_bias_layer2/4)
    # bias_data = np.append(bias_data, sps_quan_bias_layer3/8)
    # bias_data = np.append(bias_data, sps_quan_bias_layer4/4)
    # write_data2coefile('../data4fpga_bin/sps_conv_bias.coe', bias_data.astype(np.int8))

    sps_conv4.weight.data = torch.tensor(sps_quan_weight_layer4)
    sps_conv4.bias.data = torch.tensor(sps_quan_bias_layer4)

    with torch.no_grad():
        sps_conv4_out_python = sps_conv4(torch.tensor(Spiking_Data4, dtype=torch.float)).cpu().numpy()

    sps_conv4_fpga_out_t0 = []
    sps_conv4_fpga_out_t1 = []
    sps_conv4_fpga_out_t2 = []
    sps_conv4_fpga_out_t3 = []

    with open('../data4fpga_bin/sps_conv4_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv4_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_conv4_fpga_out_t0 = np.stack(sps_conv4_fpga_out_t0).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_conv4_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv4_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_conv4_fpga_out_t1 = np.stack(sps_conv4_fpga_out_t1).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_conv4_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv4_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_conv4_fpga_out_t2 = np.stack(sps_conv4_fpga_out_t2).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_conv4_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_conv4_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_conv4_fpga_out_t3 = np.stack(sps_conv4_fpga_out_t3).reshape(384, 8, 8)
    sps_conv4_out_fpga = np.stack([sps_conv4_fpga_out_t0, sps_conv4_fpga_out_t1, sps_conv4_fpga_out_t2, sps_conv4_fpga_out_t3])
    sps_conv4_diff = sps_conv4_out_fpga - sps_conv4_out_python

    sps_conv4_out_python = torch.tensor(sps_conv4_out_python).unsqueeze(1)
    sps_lif4_out_python = sps_proj_lif4(sps_conv4_out_python).squeeze(dim=1).cpu().numpy()

    sps_lif4_fpga_out_t0 = []
    sps_lif4_fpga_out_t1 = []
    sps_lif4_fpga_out_t2 = []
    sps_lif4_fpga_out_t3 = []
    with open('../data4fpga_bin/sps_lif4_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif4_fpga_out_t0.append(float(line.strip()))
    f.close()
    sps_lif4_fpga_out_t0 = np.stack(sps_lif4_fpga_out_t0).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_lif4_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif4_fpga_out_t1.append(float(line.strip()))
    f.close()
    sps_lif4_fpga_out_t1 = np.stack(sps_lif4_fpga_out_t1).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_lif4_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif4_fpga_out_t2.append(float(line.strip()))
    f.close()
    sps_lif4_fpga_out_t2 = np.stack(sps_lif4_fpga_out_t2).reshape(384, 8, 8)
    with open('../data4fpga_bin/sps_lif4_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                sps_lif4_fpga_out_t3.append(float(line.strip()))
    f.close()
    sps_lif4_fpga_out_t3 = np.stack(sps_lif4_fpga_out_t3).reshape(384, 8, 8)
    sps_lif4_out_fpga = np.stack([sps_lif4_fpga_out_t0, sps_lif4_fpga_out_t1, sps_lif4_fpga_out_t2, sps_lif4_fpga_out_t3])
    sps_lif4_diff = sps_lif4_out_fpga - sps_lif4_out_python
    if np.sum(sps_lif4_diff) == 0:
        print('sps lif4 \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('sps lif4 \033[4;38;2;200;0;0mfalse\033[0m!')

    # print(1)
    ##### end spiking rpe-conv #####

    ##### embed patch #####
    embedpatch_fpga_out_t0 = []
    embedpatch_fpga_out_t1 = []
    embedpatch_fpga_out_t2 = []
    embedpatch_fpga_out_t3 = []
    with open('../data4fpga_bin/embedpatch_out_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_out_t0.append(float(line.strip()))
    f.close()
    embedpatch_fpga_out_t0 = np.stack(embedpatch_fpga_out_t0).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_out_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_out_t1.append(float(line.strip()))
    f.close()
    embedpatch_fpga_out_t1 = np.stack(embedpatch_fpga_out_t1).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_out_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_out_t2.append(float(line.strip()))
    f.close()
    embedpatch_fpga_out_t2 = np.stack(embedpatch_fpga_out_t2).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_out_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_out_t3.append(float(line.strip()))
    f.close()
    embedpatch_fpga_out_t3 = np.stack(embedpatch_fpga_out_t3).reshape(384, 8, 8)
    embedpatch_out_fpga = np.stack([embedpatch_fpga_out_t0, embedpatch_fpga_out_t1, embedpatch_fpga_out_t2, embedpatch_fpga_out_t3])

    ## from uppper
    embedpatch_out_python_v1 = sps_lif4_out_fpga + sps_maxpool2_out_fpga
    diff_embedpatch = embedpatch_out_python_v1 - embedpatch_out_fpga
    if np.sum(diff_embedpatch) == 0:
        print('embed patch \033[4;38;2;0;200;0mright\033[0m!')
    else:
        print('embed patch \033[4;38;2;200;0;0mfalse\033[0m!')

    embedpatch_fpga_in00_t0 = []
    embedpatch_fpga_in00_t1 = []
    embedpatch_fpga_in00_t2 = []
    embedpatch_fpga_in00_t3 = []
    with open('../data4fpga_bin/embedpatch_in00_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in00_t0.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in00_t0 = np.stack(embedpatch_fpga_in00_t0).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_in00_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in00_t1.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in00_t1 = np.stack(embedpatch_fpga_in00_t1).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_in00_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in00_t2.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in00_t2 = np.stack(embedpatch_fpga_in00_t2).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_in00_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in00_t3.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in00_t3 = np.stack(embedpatch_fpga_in00_t3).reshape(384, 8, 8)
    embedpatch_in00_fpga = np.stack([embedpatch_fpga_in00_t0, embedpatch_fpga_in00_t1, embedpatch_fpga_in00_t2, embedpatch_fpga_in00_t3])

    embedpatch_fpga_in01_t0 = []
    embedpatch_fpga_in01_t1 = []
    embedpatch_fpga_in01_t2 = []
    embedpatch_fpga_in01_t3 = []
    with open('../data4fpga_bin/embedpatch_in01_t0.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in01_t0.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in01_t0 = np.stack(embedpatch_fpga_in01_t0).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_in01_t1.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in01_t1.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in01_t1 = np.stack(embedpatch_fpga_in01_t1).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_in01_t2.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in01_t2.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in01_t2 = np.stack(embedpatch_fpga_in01_t2).reshape(384, 8, 8)
    with open('../data4fpga_bin/embedpatch_in01_t3.txt', 'r') as f:
        for line in f:
            if not line.strip() == 'x':
                embedpatch_fpga_in01_t3.append(float(line.strip()))
    f.close()
    embedpatch_fpga_in01_t3 = np.stack(embedpatch_fpga_in01_t3).reshape(384, 8, 8)
    embedpatch_in01_fpga = np.stack([embedpatch_fpga_in01_t0, embedpatch_fpga_in01_t1, embedpatch_fpga_in01_t2, embedpatch_fpga_in01_t3])

    embedpatch_out_python_v2 = embedpatch_in01_fpga + embedpatch_in00_fpga
    diff_embedpatch = embedpatch_out_python_v2 - embedpatch_out_fpga
    diff_1 = embedpatch_in01_fpga - sps_maxpool2_out_fpga

    print('diff_embedpatch:{}, diff_1:{}'.format(diff_embedpatch.sum(), diff_1.sum()))
    # print(1)

if __name__ == '__main__':
    # fc1 = nn.Linear(384, 384)
    # data = torch.ones(1, 64, 384)
    #
    # with torch.no_grad():
    #     out = fc1(data).cpu().numpy()
    #
    # weight = fc1.weight.data.cpu().numpy()
    # # sum = np.sum(weight[:, 0])
    # print(1)

    main()
    # # fetch code gen
    # data1 = np.stack([1, 1, 8, 1, 8, 1], dtype=np.int16)
    # data2 = np.stack([0, 2, 0, 3, 0, 2], dtype=np.int16)
    # data3 = np.stack([64, 128, 0, 256, 0, 128], dtype=np.int16)
    # data4 = np.stack([48, 96, 192, 192, 384, 384], dtype=np.int16)
    # data5 = np.stack([96, 192, 192, 384, 384, 384], dtype=np.int16)
    # data6 = np.stack([34, 34, 34, 18, 18, 10], dtype=np.int16)
    #
    # result = []
    #
    # for ii in range(len(data6)):
    #     num1 = data1[ii].tobytes()
    #     num2 = data2[ii].tobytes()
    #     num3 = data3[ii].tobytes()
    #     num4 = data4[ii].tobytes()
    #     num5 = data5[ii].tobytes()
    #     num6 = data6[ii].tobytes()
    #
    #     val1 = int.from_bytes(num1, 'little')
    #     val2 = int.from_bytes(num2, 'little')
    #     val3 = int.from_bytes(num3, 'little')
    #     val4 = int.from_bytes(num4, 'little')
    #     val5 = int.from_bytes(num5, 'little')
    #     val6 = int.from_bytes(num6, 'little')
    #
    #     result.append((val1 << 80) | (val2 << 64) | (val3 << 48) | (val4 << 32) | (val5 << 16) | val6)
    #
    # filename = '../data4fpga_bin/fetch_code.coe'
    # # print(f"拼接后的96位数: {result:024x}")
    # with open(filename, 'w') as coefile:
    #     coefile.write("memory_initialization_radix=16;\n")
    #     coefile.write("memory_initialization_vector=\n")
    #     for i, value in enumerate(result):
    #         hex_value = f"{value:024x}"
    #         coefile.write(f"{hex_value}")
    #         if i < len(result) - 1:
    #             coefile.write(",\n")
    #         else:
    #             coefile.write("")
    #     coefile.write(";\n")
