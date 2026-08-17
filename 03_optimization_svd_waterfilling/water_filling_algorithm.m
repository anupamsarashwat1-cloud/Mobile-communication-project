function [P_opt, mu, active_streams] = water_filling_algorithm(sigma_sq, P_total, noise_var)
% WATER_FILLING_ALGORITHM Computes optimal power allocation across spatial eigenmodes.
%
% Inputs:
%   sigma_sq   - Vector of squared singular values [sigma_1^2, sigma_2^2, ..., sigma_r^2] (descending)
%   P_total    - Total available transmit power (e.g. 1.0)
%   noise_var  - Noise variance sigma_n^2
%
% Outputs:
%   P_opt          - Optimal power allocated to each eigenmode (same size as sigma_sq)
%   mu             - The computed water-level threshold
%   active_streams - Number of active streams receiving non-zero power (rank allocation)
%
% Optimization Problem:
%   max sum(log2(1 + P_i * sigma_i^2 / noise_var))
%   subject to sum(P_i) = P_total, P_i >= 0

sigma_sq = sigma_sq(:)'; % Row vector
r = length(sigma_sq);
inv_snr_subchannels = noise_var ./ sigma_sq;

% Iterative water-pouring:
% Start assuming all r streams are active. If any stream receives negative power,
% deactivate the weakest stream and recompute water level among remaining active streams.
active_mask = true(1, r);

while true
    num_active = sum(active_mask);
    if num_active == 0
        P_opt = zeros(size(sigma_sq));
        mu = 0;
        active_streams = 0;
        return;
    end
    
    % Water level mu = (P_total + sum(1 / SNR_i)) / num_active
    mu = (P_total + sum(inv_snr_subchannels(active_mask))) / num_active;
    
    % Temporary power calculation
    P_temp = zeros(1, r);
    P_temp(active_mask) = mu - inv_snr_subchannels(active_mask);
    
    % Check if any active channel has non-positive power
    violators = active_mask & (P_temp <= 0);
    if ~any(violators)
        P_opt = max(0, P_temp);
        active_streams = num_active;
        break;
    else
        % Deactivate weakest violating channel
        violating_indices = find(violators);
        active_mask(violating_indices(end)) = false;
    end
end

end
