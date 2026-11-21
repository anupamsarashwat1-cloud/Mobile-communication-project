function [s1_hat, s2_hat] = alamouti_combiner_hw(r1_t1, r2_t1, r1_t2, r2_t2, h11, h12, h21, h22)
%#codegen
% ALAMOUTI_COMBINER_HW Hardware-synthesizable 2x2 Alamouti MRC Combiner
% Recombines received samples across 2 receive antennas and 2 time slots.
%
% Diversity Order: d = 4
%
% Detection Equations:
%   s1_num = conj(h11)*r1_t1 + conj(h21)*r2_t1 + h12*conj(r1_t2) + h22*conj(r2_t2)
%   s2_num = conj(h12)*r1_t1 + conj(h22)*r2_t1 - h11*conj(r1_t2) - h21*conj(r2_t2)
%   H_norm_sq = |h11|^2 + |h12|^2 + |h21|^2 + |h22|^2

SQRT2 = single(1.4142135623730951);

% Frobenius squared norm of channel matrix
h11_sq = real(h11)*real(h11) + imag(h11)*imag(h11);
h12_sq = real(h12)*real(h12) + imag(h12)*imag(h12);
h21_sq = real(h21)*real(h21) + imag(h21)*imag(h21);
h22_sq = real(h22)*real(h22) + imag(h22)*imag(h22);
H_norm_sq = h11_sq + h12_sq + h21_sq + h22_sq;

% Ensure non-zero denominator for fixed-point stability
if H_norm_sq < single(1e-6)
    denom = single(1e-6);
else
    denom = H_norm_sq;
end

% Maximal Ratio Combining
term1_s1 = conj(h11) * r1_t1;
term2_s1 = conj(h21) * r2_t1;
term3_s1 = h12 * conj(r1_t2);
term4_s1 = h22 * conj(r2_t2);
s1_num = term1_s1 + term2_s1 + term3_s1 + term4_s1;

term1_s2 = conj(h12) * r1_t1;
term2_s2 = conj(h22) * r2_t1;
term3_s2 = -h11 * conj(r1_t2);
term4_s2 = -h21 * conj(r2_t2);
s2_num = term1_s2 + term2_s2 + term3_s2 + term4_s2;

% Normalization
s1_hat = (s1_num * SQRT2) / denom;
s2_hat = (s2_num * SQRT2) / denom;

end
