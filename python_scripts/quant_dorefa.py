import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np


class qfn(torch.autograd.Function):
    @staticmethod
    def forward(ctx, input):
        out = torch.round(input)
        return out

    @staticmethod
    def backward(ctx, grad_output):
        grad_input = grad_output.clone()
        return grad_input

class weight_quantize_fn(nn.Module):
    def __init__(self, w_bit):
        super(weight_quantize_fn, self).__init__()
        assert w_bit <= 8 or w_bit == 32
        self.w_bit = w_bit
        self.uniform_q = qfn().apply

    def forward(self, x):
        if self.w_bit == 32:
            weight_q = x
        elif self.w_bit == 1:
            E = torch.mean(torch.abs(x)).detach()
            weight_q = self.uniform_q(x / E) * E
        else:
            # weight = torch.tanh(x)
            max_w = torch.max(torch.abs(x)).detach()
            # weight = weight / 2 / max_w + 0.5
            # weight_q = max_w * (2 * self.uniform_q(weight) - 1)
            scale = (2 ** (self.w_bit - 1) - 1) / max_w
            scale = 2 ** torch.floor(torch.log2(scale))
            weight_q = self.uniform_q(scale * x)
        return weight_q / scale


class Conv2d_Q(nn.Conv2d):
    def __init__(self, in_channels, out_channels, kernel_size, stride=1, padding=0, dilation=1, groups=1, bias=True, w_bit=8):
        super(Conv2d_Q, self).__init__(in_channels, out_channels, kernel_size, stride, padding, dilation, groups, bias)
        self.w_bit = w_bit
        self.quantize_fn = weight_quantize_fn(w_bit=w_bit)

    def forward(self, input, order=None):
        weight = self.weight
        weight_q = self.quantize_fn(weight)
        bias_q = None
        if self.bias is not None:
            bias_temp = self.bias
            bias_q = self.quantize_fn(bias_temp)
        return F.conv2d(input, weight_q, bias_q, self.stride, self.padding, self.dilation, self.groups)

class Linear_Q(nn.Linear):
    def __init__(self, in_features, out_features, bias=True, w_bit=8):
        super(Linear_Q, self).__init__(in_features, out_features, bias)
        self.w_bit = w_bit
        self.quantize_fn = weight_quantize_fn(w_bit=w_bit)

    def forward(self, input):
        weight = self.weight
        weight_q = self.quantize_fn(weight)
        bias_q = None
        if self.bias is not None:
            bias_temp = self.bias
            bias_q = self.quantize_fn(bias_temp)
        return F.linear(input, weight_q, bias_q)

