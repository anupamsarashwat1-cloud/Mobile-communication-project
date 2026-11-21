function [P1, P2, active_rank] = water_filling_hw(sigma1_sq, sigma2_sq, P_total, noise_var)
%#codegen
% WATER_FILLING_HW Hardware-synthesizable 2-stream Water-Filling power allocation
% Completely unrolled into a deterministic 2-stage pipeline (Zero dynamic while-loops)
%
% Optimization Problem:
%   max log2(1 + P1*sigma1^2/noise_var) + log2(1 + P2*sigma2^2/noise_var)
%   subject to P1 + P2 = P_total, P1 >= 0, P2 >= 0
%
% Inputs:
%   sigma1_sq, sigma2_sq - Squared singular values (sigma1_sq >= sigma2_sq)
%   P_total              - Total power budget (e.g. 1.0)
%   noise_var            - Noise variance (1 / SNR)
%
% Outputs:
%   P1, P2               - Optimal power allocated to stream 1 and stream 2
%   active_rank          - Number of active streams (1 or 2)

% Inverse sub-channel SNR
inv_snr1 = noise_var / max(sigma1_sq, single(1e-6));
inv_snr2 = noise_var / max(sigma2_sq, single(1e-6));

% Stage 1: Assume both streams active (rank = 2)
% Water level mu_2 = (P_total + inv_snr1 + inv_snr2) / 2
mu_2 = (P_total + inv_snr1 + inv_snr2) * single(0.5);

% Temporary power for stream 2 (weakest stream)
P2_temp = mu_2 - inv_snr2;

if P2_temp > single(0.0)
    % Both streams active (Rank-2 Spatial Multiplexing)
    P2 = P2_temp;
    P1 = mu_2 - inv_snr1;
    active_rank = single(2);
else
    % Stream 2 violates non-negativity: allocate 100% power to stream 1 (Rank-1)
    P1 = P_total;
    P2 = single(0.0);
    active_rank = single(1);
end

end
