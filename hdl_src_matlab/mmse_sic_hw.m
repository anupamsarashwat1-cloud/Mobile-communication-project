function [s1_re, s1_im, s2_re, s2_im] = mmse_sic_hw(...
    r1_re, r1_im, r2_re, r2_im, ...
    h11_re, h11_im, h12_re, h12_im, ...
    h21_re, h21_im, h22_re, h22_im, ...
    noise_var, mod_order)
%#codegen
% MMSE_SIC_HW Ordered MMSE-SIC Receiver for 2x2 MIMO in Pure Scalar Real/Imag Channels

INV_SQRT2 = single(0.7071067811865475);

% Gram matrix diagonal elements: g11 = ||h1||^2 + 2*sigma_n^2, g22 = ||h2||^2 + 2*sigma_n^2
h1_sq = h11_re*h11_re + h11_im*h11_im + h21_re*h21_re + h21_im*h21_im;
h2_sq = h12_re*h12_re + h12_im*h12_im + h22_re*h22_re + h22_im*h22_im;

diag_reg = single(2.0) * noise_var;
g11 = h1_sq + diag_reg;
g22 = h2_sq + diag_reg;

% Off-diagonal inner product h1^H * h2 = (h11*)*h12 + (h21*)*h22
g12_re =  (h11_re*h12_re + h11_im*h12_im) + (h21_re*h22_re + h21_im*h22_im);
g12_im =  (h11_re*h12_im - h11_im*h12_re) + (h21_re*h22_im - h21_im*h22_re);

% Determinant det(G) = g11*g22 - |g12|^2
det_g = g11*g22 - (g12_re*g12_re + g12_im*g12_im);
if det_g < single(1e-6)
    inv_det = single(1.0) / single(1e-6);
else
    inv_det = single(1.0) / det_g;
end

% Inverted Gram matrix elements:
inv_g11 = g22 * inv_det;
inv_g12_re = -g12_re * inv_det;
inv_g12_im = -g12_im * inv_det;

% First row of W_mmse = [inv_g11, inv_g12] * H^H
% w11 = inv_g11 * conj(h11) + inv_g12 * conj(h12)
w11_re = inv_g11 * h11_re + (inv_g12_re * h12_re + inv_g12_im * h12_im);
w11_im = -inv_g11 * h11_im + (-inv_g12_re * h12_im + inv_g12_im * h12_re);

% w12 = inv_g11 * conj(h21) + inv_g12 * conj(h22)
w12_re = inv_g11 * h21_re + (inv_g12_re * h22_re + inv_g12_im * h22_im);
w12_im = -inv_g11 * h21_im + (-inv_g12_re * h22_im + inv_g12_im * h22_re);

% Detect stream 1: s1_raw = (w11*r1 + w12*r2) * sqrt(2)
term1_re = w11_re*r1_re - w11_im*r1_im;
term1_im = w11_re*r1_im + w11_im*r1_re;
term2_re = w12_re*r2_re - w12_im*r2_im;
term2_im = w12_re*r2_im + w12_im*r2_re;

s1_raw_re = (term1_re + term2_re) * single(1.41421356);
s1_raw_im = (term1_im + term2_im) * single(1.41421356);

s1_re = s1_raw_re;
s1_im = s1_raw_im;

% Hard Slicing of stream 1
[s1_sl_re, s1_sl_im] = qam_slicer_hw(s1_raw_re, s1_raw_im, mod_order);

% Stream 1 interference cancellation: r_canc = r - h1 * (s1_sliced / sqrt(2))
s1_sc_re = s1_sl_re * INV_SQRT2;
s1_sc_im = s1_sl_im * INV_SQRT2;

sub1_re = h11_re*s1_sc_re - h11_im*s1_sc_im;
sub1_im = h11_re*s1_sc_im + h11_im*s1_sc_re;
r1_canc_re = r1_re - sub1_re;
r1_canc_im = r1_im - sub1_im;

sub2_re = h21_re*s1_sc_re - h21_im*s1_sc_im;
sub2_im = h21_re*s1_sc_im + h21_im*s1_sc_re;
r2_canc_re = r2_re - sub2_re;
r2_canc_im = r2_im - sub2_im;

% Detect stream 2 using MRC on column 2 of H
if h2_sq < single(1e-6)
    denom2 = single(1e-6);
else
    denom2 = h2_sq;
end

mrc1_re =  h12_re*r1_canc_re + h12_im*r1_canc_im;
mrc1_im =  h12_re*r1_canc_im - h12_im*r1_canc_re;
mrc2_re =  h22_re*r2_canc_re + h22_im*r2_canc_im;
mrc2_im =  h22_re*r2_canc_im - h22_im*r2_canc_re;

s2_re = ((mrc1_re + mrc2_re) * single(1.41421356)) / denom2;
s2_im = ((mrc1_im + mrc2_im) * single(1.41421356)) / denom2;

end
