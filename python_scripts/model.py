import torch
import torch.nn as nn
from spikingjelly.clock_driven.neuron import MultiStepLIFNode
from timm.models.layers import to_2tuple, trunc_normal_, DropPath
from timm.models.registry import register_model
from timm.models.vision_transformer import _cfg
import torch.nn.functional as F
from quant_dorefa import *
from functools import partial
import numpy as np
from scipy.io import savemat
import time
__all__ = ['spikformer', 'spikformer_Q', 'SPS', 'MLP', 'SSA', 'Block']


class MLP(nn.Module):
    def __init__(self, in_features, hidden_features=None, out_features=None, drop=0.):
        super().__init__()
        out_features = out_features or in_features
        hidden_features = hidden_features or in_features
        self.fc1_linear = nn.Linear(in_features, hidden_features)
        self.fc1_bn = nn.BatchNorm1d(hidden_features)
        self.fc1_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.fc2_linear = nn.Linear(hidden_features, out_features)
        self.fc2_bn = nn.BatchNorm1d(out_features)
        self.fc2_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.c_hidden = hidden_features
        self.c_output = out_features

    def forward(self, x):
        T,B,N,C = x.shape
        x_ = x.flatten(0, 1)#(4,128,64,384)->(512,64,384)
        x = self.fc1_linear(x_)#(512,64,1536)
        x = self.fc1_bn(x.transpose(-1, -2)).transpose(-1, -2).reshape(T, B, N, self.c_hidden).contiguous()#(4,128,64,1536)
        x = self.fc1_lif(x)

        x = self.fc2_linear(x.flatten(0,1))#(512,64,384)
        x = self.fc2_bn(x.transpose(-1, -2)).transpose(-1, -2).reshape(T, B, N, C).contiguous()#(4,128,64,384)
        x = self.fc2_lif(x)
        return x


class SSA(nn.Module):
    def __init__(self, dim, num_heads=8, qkv_bias=False, qk_scale=None, attn_drop=0., proj_drop=0., sr_ratio=1):
        super().__init__()
        assert dim % num_heads == 0, f"dim {dim} should be divided by num_heads {num_heads}."
        self.dim = dim
        self.num_heads = num_heads
        self.scale = 0.125
        self.q_linear = nn.Linear(dim, dim)
        self.q_bn = nn.BatchNorm1d(dim)
        self.q_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.k_linear = nn.Linear(dim, dim)
        self.k_bn = nn.BatchNorm1d(dim)
        self.k_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.v_linear = nn.Linear(dim, dim)
        self.v_bn = nn.BatchNorm1d(dim)
        self.v_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')
        self.attn_lif = MultiStepLIFNode(tau=2.0, v_threshold=0.5, detach_reset=True, backend='torch')

        self.proj_linear = nn.Linear(dim, dim)
        self.proj_bn = nn.BatchNorm1d(dim)
        self.proj_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

    def forward(self, x):
        T,B,N,C = x.shape#（4, 128, 64, 384）

        x_for_qkv = x.flatten(0, 1)  # TB, N, C   #（512,64,384)
        q_linear_out = self.q_linear(x_for_qkv)  # [TB, N, C]
        q_linear_out = self.q_bn(q_linear_out. transpose(-1, -2)).transpose(-1, -2).reshape(T, B, N, C).contiguous() # (4, 128, 64, 384)
        q_linear_out = self.q_lif(q_linear_out) # (4, 128, 64, 384)
        q = q_linear_out.reshape(T, B, N, self.num_heads, C//self.num_heads).permute(0, 1, 3, 2, 4).contiguous()

        k_linear_out = self.k_linear(x_for_qkv)
        k_linear_out = self.k_bn(k_linear_out. transpose(-1, -2)).transpose(-1, -2).reshape(T, B, N, C).contiguous()
        k_linear_out = self.k_lif(k_linear_out)
        k = k_linear_out.reshape(T, B, N, self.num_heads, C//self.num_heads).permute(0, 1, 3, 2, 4).contiguous()

        v_linear_out = self.v_linear(x_for_qkv)
        v_linear_out = self.v_bn(v_linear_out. transpose(-1, -2)).transpose(-1, -2).reshape(T, B, N, C).contiguous()
        v_linear_out = self.v_lif(v_linear_out)
        v = v_linear_out.reshape(T, B, N, self.num_heads, C//self.num_heads).permute(0, 1, 3, 2, 4).contiguous()

        attn = (q @ k.transpose(-2, -1)) * self.scale
        x = attn @ v
        x = x.transpose(2, 3).reshape(T, B, N, C).contiguous()
        x = self.attn_lif(x)
        x = x.flatten(0, 1)#(512,64,384)
        x = self.proj_lif(self.proj_bn(self.proj_linear(x).transpose(-1, -2)).transpose(-1, -2).reshape(T, B, N, C))
        return x

class Block(nn.Module):
    def __init__(self, dim, num_heads, mlp_ratio=4., qkv_bias=False, qk_scale=None, drop=0., attn_drop=0.,
                 drop_path=0., norm_layer=nn.LayerNorm, sr_ratio=1):
        super().__init__()
        self.norm1 = norm_layer(dim)
        self.attn = SSA(dim, num_heads=num_heads, qkv_bias=qkv_bias, qk_scale=qk_scale,
                              attn_drop=attn_drop, proj_drop=drop, sr_ratio=sr_ratio)
        self.norm2 = norm_layer(dim)
        mlp_hidden_dim = int(dim * mlp_ratio)
        self.mlp = MLP(in_features=dim, hidden_features=mlp_hidden_dim, drop=drop)
    #Block的整体实现
    def forward(self, x):
        x = x + self.attn(x)#(4,128,64,384)->(4,128,64,384)
        x = x + self.mlp(x)#(4,128,64,384)->(4,128,64,384)
        return x


class SPS(nn.Module):
    def __init__(self, img_size_h=128, img_size_w=128, patch_size=4, in_channels=2, embed_dims=256):
        super().__init__()
        self.image_size = [img_size_h, img_size_w]
        patch_size = to_2tuple(patch_size)
        self.patch_size = patch_size
        self.C = in_channels
        self.H, self.W = self.image_size[0] // patch_size[0], self.image_size[1] // patch_size[1]
        self.num_patches = self.H * self.W
        self.proj_conv = nn.Conv2d(in_channels, embed_dims//8, kernel_size=3, stride=1, padding=1, bias=False)
        self.proj_bn = nn.BatchNorm2d(embed_dims//8)
        self.proj_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.proj_conv1 = nn.Conv2d(embed_dims//8, embed_dims//4, kernel_size=3, stride=1, padding=1, bias=False)
        self.proj_bn1 = nn.BatchNorm2d(embed_dims//4)
        self.proj_lif1 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.proj_conv2 = nn.Conv2d(embed_dims//4, embed_dims//2, kernel_size=3, stride=1, padding=1, bias=False)
        self.proj_bn2 = nn.BatchNorm2d(embed_dims//2)
        self.proj_lif2 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')
        self.maxpool2 = torch.nn.MaxPool2d(kernel_size=3, stride=2, padding=1, dilation=1, ceil_mode=False)

        self.proj_conv3 = nn.Conv2d(embed_dims//2, embed_dims, kernel_size=3, stride=1, padding=1, bias=False)
        self.proj_bn3 = nn.BatchNorm2d(embed_dims)
        self.proj_lif3 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')
        self.maxpool3 = torch.nn.MaxPool2d(kernel_size=3, stride=2, padding=1, dilation=1, ceil_mode=False)

        self.rpe_conv = nn.Conv2d(embed_dims, embed_dims, kernel_size=3, stride=1, padding=1, bias=False)
        self.rpe_bn = nn.BatchNorm2d(embed_dims)
        self.rpe_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

    def forward(self, x):
        T, B, C, H, W = x.shape
        x = self.proj_conv(x.flatten(0, 1)) # have some fire value   #flatten(512,3,32,32)->(512,48,32,32)
        x = self.proj_bn(x).reshape(T, B, -1, H, W).contiguous()#(4,128,48,32,32)
        x = self.proj_lif(x).flatten(0, 1).contiguous()#(4,128,48,32,32)->(512,48,32,32)

        x = self.proj_conv1(x)#(512,96,32,32)
        x = self.proj_bn1(x).reshape(T, B, -1, H, W).contiguous()#(4,128,96,32,32)
        x = self.proj_lif1(x).flatten(0, 1).contiguous()#(4,128,96,32,32)->(512,96,32,32)

        x = self.proj_conv2(x)#(512,192,32,32)
        x = self.proj_bn2(x).reshape(T, B, -1, H, W).contiguous()#(4,128,192,32,32)
        x = self.proj_lif2(x).flatten(0, 1).contiguous()#(4,128,192,32,32)->(512,192,32,32)
        x = self.maxpool2(x)#(512,192,16,16)

        x = self.proj_conv3(x)#(512,384,16,16)
        x = self.proj_bn3(x).reshape(T, B, -1, H//2, W//2).contiguous()#(512,384,16,16)->(4,128,384,16,16)
        x = self.proj_lif3(x).flatten(0, 1).contiguous()#(512, 384, 16, 16)
        x = self.maxpool3(x)#(512, 384, 8, 8)

        x_feat = x.reshape(T, B, -1, H//4, W//4).contiguous()#(4, 128, 384, 8, 8)
        x = self.rpe_conv(x)#(512,384,8,8)
        x = self.rpe_bn(x).reshape(T, B, -1, H//4, W//4).contiguous()#(4,128,384,8,8)
        x = self.rpe_lif(x)#(4, 128, 384, 8, 8)
        x = x + x_feat#(4, 128, 384, 8, 8)

        x = x.flatten(-2).transpose(-1, -2)  # T,B,N,C   (4,128,64,384)
        return x


class Spikformer(nn.Module):
    def __init__(self,
                 img_size_h=128, img_size_w=128, patch_size=16, in_channels=2, num_classes=11,
                 embed_dims=[64, 128, 256], num_heads=[1, 2, 4], mlp_ratios=[4, 4, 4], qkv_bias=False, qk_scale=None,
                 drop_rate=0., attn_drop_rate=0., drop_path_rate=0., norm_layer=nn.LayerNorm,
                 depths=[6, 8, 6], sr_ratios=[8, 4, 2], T = 4
                 ):
        super().__init__()
        self.T = T  # time step
        self.num_classes = num_classes
        self.depths = depths

        dpr = [x.item() for x in torch.linspace(0, drop_path_rate, depths)]  # stochastic depth decay rule

        patch_embed = SPS(img_size_h=img_size_h,
                                 img_size_w=img_size_w,
                                 patch_size=patch_size,
                                 in_channels=in_channels,
                                 embed_dims=embed_dims)

        block = nn.ModuleList([Block(
            dim=embed_dims, num_heads=num_heads, mlp_ratio=mlp_ratios, qkv_bias=qkv_bias,
            qk_scale=qk_scale, drop=drop_rate, attn_drop=attn_drop_rate, drop_path=dpr[j],
            norm_layer=norm_layer, sr_ratio=sr_ratios)
            for j in range(depths)])

        setattr(self, f"patch_embed", patch_embed)
        setattr(self, f"block", block)

        # classification head
        self.head = nn.Linear(embed_dims, num_classes) if num_classes > 0 else nn.Identity()
        self.apply(self._init_weights)

    @torch.jit.ignore
    def _get_pos_embed(self, pos_embed, patch_embed, H, W):
        if H * W == self.patch_embed1.num_patches:
            return pos_embed
        else:
            return F.interpolate(
                pos_embed.reshape(1, patch_embed.H, patch_embed.W, -1).permute(0, 3, 1, 2),
                size=(H, W), mode="bilinear").reshape(1, -1, H * W).permute(0, 2, 1)

    def _init_weights(self, m):
        if isinstance(m, nn.Linear):
            trunc_normal_(m.weight, std=.02)
            if isinstance(m, nn.Linear) and m.bias is not None:
                nn.init.constant_(m.bias, 0)
        elif isinstance(m, nn.LayerNorm):
            nn.init.constant_(m.bias, 0)
            nn.init.constant_(m.weight, 1.0)

    def forward_features(self, x):

        block = getattr(self, f"block")
        patch_embed = getattr(self, f"patch_embed")

        x = patch_embed(x)#(128,3,32,32)->(4,128,64,384)
        for blk in block:
            x = blk(x) #(4, 128, 64, 384)->(4,128,64,384)
        return x.mean(2)#(4,128,384)

    def forward(self, x):
        x = (x.unsqueeze(0)).repeat(self.T, 1, 1, 1, 1)
        x = self.forward_features(x)
        x = self.head(x.mean(0))  #(解点火率后（128,384））->(128,10)
        return x


@register_model
def spikformer(pretrained=False, **kwargs):
    model = Spikformer(
        # img_size_h=224, img_size_w=224,
        # patch_size=16, embed_dims=768, num_heads=12, mlp_ratios=4,
        # in_channels=3, num_classes=1000, qkv_bias=False,
        # norm_layer=partial(nn.LayerNorm, eps=1e-6), depths=12, sr_ratios=1,
        **kwargs
    )
    model.default_cfg = _cfg()
    return model


#------------------------------------ quantized model ------------------------------------#

class Spikformer_Q(nn.Module):
    def __init__(self, img_size_h=128, img_size_w=128, patch_size=16, in_channels=2, num_classes=11,
                 embed_dims=[64, 128, 256], num_heads=[1, 2, 4], mlp_ratios=[4, 4, 4], qkv_bias=False, qk_scale=None,
                 drop_rate=0., attn_drop_rate=0., drop_path_rate=0., norm_layer=nn.LayerNorm,
                 depths=[6, 8, 6], sr_ratios=[8, 4, 2], T = 4
                 ):
        super().__init__()
        self.T = T  # time step
        self.num_classes = num_classes
        self.depths = depths

        dpr = [x.item() for x in torch.linspace(0, drop_path_rate, depths)]  # stochastic depth decay rule

        patch_embed = SPS_Q(img_size_h=img_size_h, img_size_w=img_size_w, patch_size=patch_size, in_channels=in_channels, embed_dims=embed_dims)

        block = nn.ModuleList([Block_Q(
            dim=embed_dims, num_heads=num_heads, mlp_ratio=mlp_ratios, qkv_bias=qkv_bias,
            qk_scale=qk_scale, drop=drop_rate, attn_drop=attn_drop_rate, drop_path=dpr[j],
            norm_layer=norm_layer, sr_ratio=sr_ratios)
            for j in range(depths)])

        setattr(self, f"patch_embed", patch_embed)
        setattr(self, f"block", block)

        # classification head
        self.head = Linear_Q(embed_dims, num_classes) if num_classes > 0 else nn.Identity()
        self.apply(self._init_weights)

    @torch.jit.ignore
    def _get_pos_embed(self, pos_embed, patch_embed, H, W):
        if H * W == self.patch_embed1.num_patches:
            return pos_embed
        else:
            return F.interpolate(
                pos_embed.reshape(1, patch_embed.H, patch_embed.W, -1).permute(0, 3, 1, 2),
                size=(H, W), mode="bilinear").reshape(1, -1, H * W).permute(0, 2, 1)


    def _init_weights(self, m):
        if isinstance(m, nn.Linear):
            trunc_normal_(m.weight, std=.02)
            if isinstance(m, nn.Linear) and m.bias is not None:
                nn.init.constant_(m.bias, 0)
        elif isinstance(m, nn.LayerNorm):
            nn.init.constant_(m.bias, 0)
            nn.init.constant_(m.weight, 1.0)


    def forward_features(self, x):

        block = getattr(self, f"block")
        patch_embed = getattr(self, f"patch_embed")

        x = patch_embed(x)#(128,3,32,32)->(4,128,64,384)
        for blk in block:
            x = blk(x) #(4, 128, 64, 384)->(4,128,64,384)
        return x.mean(2)#(4,128,384)

    def forward(self, x):
        x = (x.unsqueeze(0)).repeat(self.T, 1, 1, 1, 1)
        x = self.forward_features(x)
        x = self.head(x.mean(0))  #(解点火率后（128,384））->(128,10)
        return x


class SPS_Q(nn.Module):
    def __init__(self, img_size_h=128, img_size_w=128, patch_size=4, in_channels=2, embed_dims=256):
        super().__init__()
        self.image_size = [img_size_h, img_size_w]
        patch_size = to_2tuple(patch_size)
        self.patch_size = patch_size
        self.C = in_channels
        self.H, self.W = self.image_size[0] // patch_size[0], self.image_size[1] // patch_size[1]
        self.num_patches = self.H * self.W
        self.proj_conv = Conv2d_Q(in_channels, embed_dims//8, kernel_size=3, stride=1, padding=1)
        self.proj_bn = nn.BatchNorm2d(embed_dims//8)
        self.proj_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.proj_conv1 = Conv2d_Q(embed_dims//8, embed_dims//4, kernel_size=3, stride=1, padding=1)
        self.proj_bn1 = nn.BatchNorm2d(embed_dims//4)
        self.proj_lif1 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.proj_conv2 = Conv2d_Q(embed_dims//4, embed_dims//2, kernel_size=3, stride=1, padding=1)
        self.proj_bn2 = nn.BatchNorm2d(embed_dims//2)
        self.proj_lif2 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')
        self.maxpool2 = torch.nn.MaxPool2d(kernel_size=3, stride=2, padding=1, dilation=1, ceil_mode=False)

        self.proj_conv3 = Conv2d_Q(embed_dims//2, embed_dims, kernel_size=3, stride=1, padding=1)
        self.proj_bn3 = nn.BatchNorm2d(embed_dims)
        self.proj_lif3 = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')
        self.maxpool3 = torch.nn.MaxPool2d(kernel_size=3, stride=2, padding=1, dilation=1, ceil_mode=False)

        self.rpe_conv = Conv2d_Q(embed_dims, embed_dims, kernel_size=3, stride=1, padding=1)
        self.rpe_bn = nn.BatchNorm2d(embed_dims)
        self.rpe_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

    def forward(self, x):
        T, B, C, H, W = x.shape
        x = self.proj_conv(x.flatten(0, 1)) # have some fire value   #flatten(512,3,32,32)->(512,48,32,32)
        x = x.reshape(T, B, -1, H, W).contiguous()#(4,128,48,32,32)
        x = self.proj_lif(x).flatten(0, 1).contiguous()#(4,128,48,32,32)->(512,48,32,32)

        x = self.proj_conv1(x)#(512,96,32,32)
        x = x.reshape(T, B, -1, H, W).contiguous()#(4,128,96,32,32)
        x = self.proj_lif1(x).flatten(0, 1).contiguous()#(4,128,96,32,32)->(512,96,32,32)

        x = self.proj_conv2(x)#(512,192,32,32)
        x = x.reshape(T, B, -1, H, W).contiguous()#(4,128,192,32,32)
        x = self.proj_lif2(x).flatten(0, 1).contiguous()#(4,128,192,32,32)->(512,192,32,32)
        x = self.maxpool2(x)#(512,192,16,16)

        x = self.proj_conv3(x)#(512,384,16,16)
        x = x.reshape(T, B, -1, H//2, W//2).contiguous()#(512,384,16,16)->(4,128,384,16,16)
        x = self.proj_lif3(x).flatten(0, 1).contiguous()#(512, 384, 16, 16)
        x = self.maxpool3(x)#(512, 384, 8, 8)

        x_feat = x.reshape(T, B, -1, H//4, W//4).contiguous()#(4, 128, 384, 8, 8)
        x = self.rpe_conv(x)#(512,384,8,8)
        x = x.reshape(T, B, -1, H//4, W//4).contiguous()#(4,128,384,8,8)
        x = self.rpe_lif(x)#(4, 128, 384, 8, 8)
        x = x + x_feat#(4, 128, 384, 8, 8)

        x = x.flatten(-2).transpose(-1, -2)  # T,B,N,C   (4,128,64,384)
        return x

class SSA_Q(nn.Module):
    def __init__(self, dim, num_heads=8, qkv_bias=False, qk_scale=None, attn_drop=0., proj_drop=0., sr_ratio=1):
        super().__init__()
        assert dim % num_heads == 0, f"dim {dim} should be divided by num_heads {num_heads}."
        self.dim = dim
        self.num_heads = num_heads
        self.scale = 0.125
        self.q_linear = Linear_Q(dim, dim)
        self.q_bn = nn.BatchNorm1d(dim)
        self.q_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.k_linear = Linear_Q(dim, dim)
        self.k_bn = nn.BatchNorm1d(dim)
        self.k_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.v_linear = Linear_Q(dim, dim)
        self.v_bn = nn.BatchNorm1d(dim)
        self.v_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')
        self.attn_lif = MultiStepLIFNode(tau=2.0, v_threshold=0.5, detach_reset=True, backend='torch')

        self.proj_linear = Linear_Q(dim, dim)
        self.proj_bn = nn.BatchNorm1d(dim)
        self.proj_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

    def forward(self, x):
        T,B,N,C = x.shape#（4, 128, 64, 384）

        x_for_qkv = x.flatten(0, 1)  # TB, N, C   #（512,64,384)
        q_linear_out = self.q_linear(x_for_qkv)  # [TB, N, C]     即公式中的x(512,64,384)*W_Q(384,384)=Q(512,64,384)
        q_linear_out = q_linear_out.reshape(T, B, N, C).contiguous()#(4, 128, 64, 384)
        q_linear_out = self.q_lif(q_linear_out)#(4, 128, 64, 384)
        q = q_linear_out.reshape(T, B, N, self.num_heads, C//self.num_heads).permute(0, 1, 3, 2, 4).contiguous()#在这里已经把张量在维度上进行切分注入到多头里了(4, 128, 64, 384)->(4, 128, 64, 12, 32)
        #np.set_printoptions(threshold=np.inf)
        #print(q)
        #self.save_mat(q)
        k_linear_out = self.k_linear(x_for_qkv) #x(512, 64, 384)*W_K(384,384)=K(512,64,384)
        k_linear_out = k_linear_out.reshape(T, B, N, C).contiguous()
        k_linear_out = self.k_lif(k_linear_out)
        k = k_linear_out.reshape(T, B, N, self.num_heads, C//self.num_heads).permute(0, 1, 3, 2, 4).contiguous()

        v_linear_out = self.v_linear(x_for_qkv)
        v_linear_out = v_linear_out.reshape(T, B, N, C).contiguous()
        v_linear_out = self.v_lif(v_linear_out)
        v = v_linear_out.reshape(T, B, N, self.num_heads, C//self.num_heads).permute(0, 1, 3, 2, 4).contiguous()

        #np.savetxt('/home/customer/jhb/spiking-transformer-master/cifar10/q.csv',q.detach().cpu().numpy(),fmt='%.2f',delimiter=',')
        attn = (q @ k.transpose(-2, -1)) * self.scale  #(4, 128, 12, 64, 32)(q) *(4, 128, 12, 32, 64)=(4, 128, 12,64,64)
        x = attn @ v#这里省略了归一化和softmax操作，直接给出自我注意力输出值 (4, 128, 12,64,64) * (4, 128, 12, 64, 32)   =(4, 128, 12, 64, 32)
        x = x.transpose(2, 3).reshape(T, B, N, C).contiguous() #(4, 128, 12, 64, 32)->(4,128,64,12,32)->(4,128,64,384)进行多头注意力的拼接
        x = self.attn_lif(x)
        x = x.flatten(0, 1)#(512,64,384)
        x = self.proj_lif(self.proj_linear(x).reshape(T, B, N, C))#(4,128,64,384)  这里的self.proj_linear.weight就是可训练的矩阵WO
        return x

class MLP_Q(nn.Module):
    def __init__(self, in_features, hidden_features=None, out_features=None, drop=0.):
        super().__init__()
        out_features = out_features or in_features
        hidden_features = hidden_features or in_features
        self.fc1_linear = Linear_Q(in_features, hidden_features)
        self.fc1_bn = nn.BatchNorm1d(hidden_features)
        self.fc1_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.fc2_linear = Linear_Q(hidden_features, out_features)
        self.fc2_bn = nn.BatchNorm1d(out_features)
        self.fc2_lif = MultiStepLIFNode(tau=2.0, detach_reset=True, backend='torch')

        self.c_hidden = hidden_features
        self.c_output = out_features

    def forward(self, x):
        T,B,N,C = x.shape
        x_ = x.flatten(0, 1)#(4,128,64,384)->(512,64,384)
        x = self.fc1_linear(x_)#(512,64,1536)
        x = x.reshape(T, B, N, self.c_hidden).contiguous()#(4,128,64,1536)
        x = self.fc1_lif(x)

        x = self.fc2_linear(x.flatten(0, 1))#(512,64,384)
        x = x.reshape(T, B, N, C).contiguous()#(4,128,64,384)
        x = self.fc2_lif(x)
        return x


class Block_Q(nn.Module):
    def __init__(self, dim, num_heads, mlp_ratio=4., qkv_bias=False, qk_scale=None, drop=0., attn_drop=0.,
                 drop_path=0., norm_layer=nn.LayerNorm, sr_ratio=1):
        super().__init__()
        self.norm1 = norm_layer(dim)
        self.attn = SSA_Q(dim, num_heads=num_heads, qkv_bias=qkv_bias, qk_scale=qk_scale, attn_drop=attn_drop, proj_drop=drop, sr_ratio=sr_ratio)
        self.norm2 = norm_layer(dim)
        mlp_hidden_dim = int(dim * mlp_ratio)
        self.mlp = MLP_Q(in_features=dim, hidden_features=mlp_hidden_dim, drop=drop)

    def forward(self, x):
        x = x + self.attn(x)#(4,128,64,384)->(4,128,64,384)
        x = x + self.mlp(x)#(4,128,64,384)->(4,128,64,384)
        return x

@register_model
def spikformer_Q(pretrained=False, **kwargs):
    model = Spikformer_Q(
        # img_size_h=224, img_size_w=224,
        # patch_size=16, embed_dims=768, num_heads=12, mlp_ratios=4,
        # in_channels=3, num_classes=1000, qkv_bias=False,
        # norm_layer=partial(nn.LayerNorm, eps=1e-6), depths=12, sr_ratios=1,
        **kwargs
    )
    model.default_cfg = _cfg()
    return model

if __name__ == '__main__':
    model = spikformer_Q(img_size_h=32, img_size_w=32, patch_size=4, in_channels=3, num_classes=10,
                 embed_dims=384, num_heads=12, mlp_ratios=4,
                 depths=4, sr_ratios=1, T = 4)
    model.eval()
    # warmup
    for i in range(10):
        with torch.no_grad():
            x = torch.randn(3, 32, 32)
            model(x)
    # test
    print("开始测试...")
    total_time = 0
    for i in range(100):
        with torch.no_grad():
            start_time = time.time()
            model(x)
            end_time = time.time()
            iteration_time = (end_time - start_time) * 1000  # 转换为毫秒
            total_time += iteration_time
            print(f"第{i+1}次推理耗时: {iteration_time:.2f}ms")
    
    avg_time = total_time / 100
    print(f"\n平均推理时间: {avg_time:.2f}ms")
    print(f"Time taken: {(end_time - start_time) / 10} seconds")