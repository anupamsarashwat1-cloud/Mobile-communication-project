function [s1_hat, s2_hat] = mmse_sic_hw(r1, r2, h11, h12, h21, h22, noise_var, mod_order)
%#codegen
% MMSE_SIC_HW Hardware-synthesizable Ordered MMSE-SIC Detector for 2x2 MIMO
%
% Algorithm:
%   1. Gram matrix G = H^H * H + 2 * noise_var * I
%   2. Closed-form 2x2 matrix inversion of G
%   3. Detect Stream 1 with MMSE weight vector w1
%   4. Hard-decision constellation slicing of Stream 1
%   5. Interference Cancellation: r_cancelled = r - h1 * s1_sliced
%   6. Detect Stream 2 via Maximal Ratio Combining (MRC) on cancelled vector

INV_SQRT2 = single(0.7071067811865475);

% 1. Form H^H * H elements
% Column 1 norm squared
g11_raw = real(h11)*real(h11) + imag(h11)*imag(h11) + real(h21)*real(h21) + imag(h21)*imag(h21);
% Column 2 norm squared
g22_raw = real(h12)*real(h12) + imag(h12)*imag(h12) + real(h22)*real(h22) + imag(h22)*imag(h22);
% Off-diagonal inner product h1^H * h2
g12_cross = conj(h11)*h12 + conj(h21)*h22;
g21_cross = conj(g12_cross);

% Add noise regularization: 2 * noise_var on diagonals
diag_reg = single(2.0) * noise_var;
g11 = g11_raw + diag_reg;
g22 = g22_raw + diag_reg;

% 2. 2x2 Determinant
det_G = g11 * g22 - (real(g12_cross)*real(g12_cross) + imag(g12_cross)*imag(g12_cross));
if det_G < single(1e-6)
    inv_det = single(1.0) / single(1e-6);
else
    inv_det = single(1.0) / det_G;
end

% Inverse matrix G^-1 elements:
% inv_G = [ g22,  -g12; -g21,  g11 ] * inv_det
inv_g11 = g22 * inv_det;
inv_g12 = -g12_cross * inv_det;

% First row of W_mmse = inv_G * H^H
% H^H = [ conj(h11), conj(h21); conj(h12), conj(h22) ]
w11 = inv_g11 * conj(h11) + inv_g12 * conj(h12);
w12 = inv_g11 * conj(h21) + inv_g12 * conj(h22);

% Stage 1: Detect stream 1 raw
s1_raw = (w11 * r1 + w12 * r2) * single(1.41421356);

% Slicing stream 1
[s1_sliced_i, s1_sliced_q] = qam_slicer_hw(real(s1_raw), imag(s1_raw), mod_order);
s1_sliced = complex(s1_sliced_i, s1_sliced_q);
s1_hat = s1_raw;

% Stage 2: Interference Cancellation of stream 1
r1_canc = r1 - h11 * (s1_sliced * INV_SQRT2);
r2_canc = r2 - h21 * (s1_sliced * INV_SQRT2);

% Detect stream 2 using MRC on column 2 of H
h2_norm_sq = g22_raw;
if h2_norm_sq < single(1e-6)
    denom2 = single(1e-6);
else
    denom2 = h2_norm_sq;
end

s2_mrc = (conj(h12) * r1_canc + conj(h22) * r2_canc) * single(1.41421356);
s2_hat = s2_mrc / denom2;

end
