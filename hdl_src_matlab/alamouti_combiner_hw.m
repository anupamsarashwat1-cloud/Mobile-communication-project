function [s1_re, s1_im, s2_re, s2_im] = alamouti_combiner_hw(...
    r1_t1_re, r1_t1_im, r2_t1_re, r2_t1_im, ...
    r1_t2_re, r1_t2_im, r2_t2_re, r2_t2_im, ...
    h11_re, h11_im, h12_re, h12_im, ...
    h21_re, h21_im, h22_re, h22_im)
%#codegen
% ALAMOUTI_COMBINER_HW Synthesizable 2x2 Alamouti MRC Combiner in Pure Real/Imag Scalar Channels
%
% Formulas:
% s1_num = conj(h11)*r1_t1 + conj(h21)*r2_t1 + h12*conj(r1_t2) + h22*conj(r2_t2)
% s2_num = conj(h12)*r1_t1 + conj(h22)*r2_t1 - h11*conj(r1_t2) - h21*conj(r2_t2)

SQRT2 = single(1.4142135623730951);

% Frobenius squared norm
H_sq = h11_re*h11_re + h11_im*h11_im + ...
       h12_re*h12_re + h12_im*h12_im + ...
       h21_re*h21_re + h21_im*h21_im + ...
       h22_re*h22_re + h22_im*h22_im;

if H_sq < single(1e-6)
    denom = single(1e-6);
else
    denom = H_sq;
end

% Term 1 for s1: conj(h11)*r1_t1 = (h11_re - j*h11_im)*(r1_t1_re + j*r1_t1_im)
t1_s1_re =  h11_re*r1_t1_re + h11_im*r1_t1_im;
t1_s1_im =  h11_re*r1_t1_im - h11_im*r1_t1_re;

% Term 2 for s1: conj(h21)*r2_t1 = (h21_re - j*h21_im)*(r2_t1_re + j*r2_t1_im)
t2_s1_re =  h21_re*r2_t1_re + h21_im*r2_t1_im;
t2_s1_im =  h21_re*r2_t1_im - h21_im*r2_t1_re;

% Term 3 for s1: h12*conj(r1_t2) = (h12_re + j*h12_im)*(r1_t2_re - j*r1_t2_im)
t3_s1_re =  h12_re*r1_t2_re + h12_im*r1_t2_im;
t3_s1_im = -h12_re*r1_t2_im + h12_im*r1_t2_re;

% Term 4 for s1: h22*conj(r2_t2) = (h22_re + j*h22_im)*(r2_t2_re - j*r2_t2_im)
t4_s1_re =  h22_re*r2_t2_re + h22_im*r2_t2_im;
t4_s1_im = -h22_re*r2_t2_im + h22_im*r2_t2_re;

s1_num_re = t1_s1_re + t2_s1_re + t3_s1_re + t4_s1_re;
s1_num_im = t1_s1_im + t2_s1_im + t3_s1_im + t4_s1_im;

% Term 1 for s2: conj(h12)*r1_t1
t1_s2_re =  h12_re*r1_t1_re + h12_im*r1_t1_im;
t1_s2_im =  h12_re*r1_t1_im - h12_im*r1_t1_re;

% Term 2 for s2: conj(h22)*r2_t1
t2_s2_re =  h22_re*r2_t1_re + h22_im*r2_t1_im;
t2_s2_im =  h22_re*r2_t1_im - h22_im*r2_t1_re;

% Term 3 for s2: -h11*conj(r1_t2)
t3_s2_re = -h11_re*r1_t2_re - h11_im*r1_t2_im;
t3_s2_im =  h11_re*r1_t2_im - h11_im*r1_t2_re;

% Term 4 for s2: -h21*conj(r2_t2)
t4_s2_re = -h21_re*r2_t2_re - h21_im*r2_t2_im;
t4_s2_im =  h21_re*r2_t2_im - h21_im*r2_t2_re;

s2_num_re = t1_s2_re + t2_s2_re + t3_s2_re + t4_s2_re;
s2_num_im = t1_s2_im + t2_s2_im + t3_s2_im + t4_s2_im;

% Scale and normalize
s1_re = (s1_num_re * SQRT2) / denom;
s1_im = (s1_num_im * SQRT2) / denom;
s2_re = (s2_num_re * SQRT2) / denom;
s2_im = (s2_num_im * SQRT2) / denom;

end
