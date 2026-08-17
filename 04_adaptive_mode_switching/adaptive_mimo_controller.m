function [selected_mode, kappa, effective_rate] = adaptive_mimo_controller(H, snr_db, mod_order)
% ADAPTIVE_MIMO_CONTROLLER Dynamically selects between Diversity and Multiplexing modes.
%
% Inputs:
%   H         - Nr x Nt instantaneous channel matrix
%   snr_db    - Instantaneous Signal-to-Noise Ratio in dB
%   mod_order - Modulation order (e.g. 4 for QPSK, 16 for 16-QAM)
%
% Outputs:
%   selected_mode  - 0: Diversity Mode (Alamouti STBC / Single Stream)
%                    1: Multiplexing Mode (2-stream Spatial Multiplexing / SVD-WF)
%   kappa          - Channel condition number sigma_max / sigma_min
%   effective_rate - Nominal spectral rate in bps/Hz for chosen mode

k = log2(mod_order);
s = svd(H);
sigma1 = s(1);
sigma2 = s(2);

if sigma2 < 1e-6
    kappa = 1e6;
else
    kappa = sigma1 / sigma2;
end

% Switching Decision Thresholds:
% At low SNR (< 8 dB) or high condition number (kappa > 4.5),
% spatial multiplexing suffers excessive error rate. Diversity mode achieves higher net goodput.
snr_threshold_db = 8.0;
kappa_threshold = 4.5;

if (snr_db < snr_threshold_db) || (kappa > kappa_threshold)
    selected_mode = 0; % Diversity Mode (Rank-1 / Alamouti STBC)
    effective_rate = 1 * k; % 1 stream * k bits/symbol
else
    selected_mode = 1; % Multiplexing Mode (Rank-2 / SVD-WF)
    effective_rate = 2 * k; % 2 streams * k bits/symbol
end

end
