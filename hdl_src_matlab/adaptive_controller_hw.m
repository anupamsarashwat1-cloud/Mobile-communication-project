function [selected_mode, kappa_is_high, active_streams] = adaptive_controller_hw(sigma1, sigma2, snr_linear, kappa_thresh, snr_thresh_linear)
%#codegen
% ADAPTIVE_CONTROLLER_HW Hardware-synthesizable Dynamic Rank Adaptation Controller
% Replaces floating-point division (kappa = sigma1/sigma2) with cross-multiplication:
%   Condition: (sigma1 > kappa_thresh * sigma2) OR (snr_linear < snr_thresh_linear)
%
% Outputs:
%   selected_mode  - 0: Diversity Mode (Alamouti STBC / Rank-1)
%                    1: Multiplexing Mode (SVD-WF / Rank-2)
%   kappa_is_high  - Boolean flag indicating ill-conditioned channel
%   active_streams - 1 or 2 streams

% Cross-multiplication check (avoids hardware divider)
cross_val = kappa_thresh * sigma2;
kappa_is_high = (sigma1 > cross_val);

% SNR threshold check
snr_is_low = (snr_linear < snr_thresh_linear);

if kappa_is_high || snr_is_low
    selected_mode  = single(0.0); % STBC Mode
    active_streams = single(1.0);
else
    selected_mode  = single(1.0); % Spatial Multiplexing Mode
    active_streams = single(2.0);
end

end
