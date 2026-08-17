function [U, S, V, P_opt, active_rank] = svd_precoder_combiner(H, P_total, noise_var)
% SVD_PRECODER_COMBINER Computes SVD-based precoding, combining, and optimal power allocation.
%
% Inputs:
%   H         - Nr x Nt Channel matrix
%   P_total   - Total transmit power
%   noise_var - Noise variance
%
% Outputs:
%   U           - Nr x Nr Left singular unitary matrix (Receiver combiner = U')
%   S           - Singular values vector (ordered descending)
%   V           - Nt x Nt Right singular unitary matrix (Transmitter precoder = V)
%   P_opt       - Optimal power allocated to each eigenmode via Water-Filling
%   active_rank - Number of active streams (rank chosen by water-filling)

[U, Sigma, V] = svd(H);
s = diag(Sigma);
sigma_sq = s.^2;

[P_opt, ~, active_rank] = water_filling_algorithm(sigma_sq, P_total, noise_var);
S = s;

end
