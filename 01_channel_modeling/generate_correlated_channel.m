function [H, R_tx, R_rx] = generate_correlated_channel(Nt, Nr, rho_tx, rho_rx, num_realizations)
% GENERATE_CORRELATED_CHANNEL Generates spatially correlated Rayleigh MIMO channel matrices.
%
% Syntax:
%   [H, R_tx, R_rx] = generate_correlated_channel(Nt, Nr, rho_tx, rho_rx, num_realizations)
%
% Inputs:
%   Nt               - Number of transmit antennas (e.g., 2 or 4)
%   Nr               - Number of receive antennas (e.g., 2 or 4)
%   rho_tx           - Transmit spatial correlation coefficient (0 <= rho_tx < 1)
%   rho_rx           - Receive spatial correlation coefficient (0 <= rho_rx < 1)
%   num_realizations - Number of channel realizations to generate (default: 1)
%
% Outputs:
%   H    - Channel matrix (Nr x Nt x num_realizations)
%   R_tx - Transmit correlation matrix (Nt x Nt)
%   R_rx - Receive correlation matrix (Nr x Nr)
%
% Mathematical Model:
%   Kronecker Correlation Model:
%     H = R_rx^(1/2) * H_iid * R_tx^(1/2)
%   where H_iid ~ CN(0, 1) represents uncorrelated i.i.d. Rayleigh flat fading.

if nargin < 5
    num_realizations = 1;
end
if nargin < 4 || isempty(rho_rx)
    rho_rx = 0;
end
if nargin < 3 || isempty(rho_tx)
    rho_tx = 0;
end

% 1. Construct Exponential / Toeplitz Spatial Correlation Matrices
% R(i, j) = rho^(|i - j|)
tx_indices = 0:(Nt - 1);
rx_indices = 0:(Nr - 1);

R_tx = rho_tx .^ abs(repmat(tx_indices, Nt, 1) - repmat(tx_indices', 1, Nt));
R_rx = rho_rx .^ abs(repmat(rx_indices, Nr, 1) - repmat(rx_indices', 1, Nr));

% 2. Matrix Square Root via Cholesky or SVD for numerical stability
% (R^(1/2) * (R^(1/2))' = R)
sqrt_R_tx = chol(R_tx, 'lower');
sqrt_R_rx = chol(R_rx, 'lower');

% 3. Generate i.i.d. Complex Gaussian Matrices: CN(0, 1) = (N(0, 1/2) + j*N(0, 1/2))
H_iid = (randn(Nr, Nt, num_realizations) + 1j * randn(Nr, Nt, num_realizations)) / sqrt(2);

% 4. Apply Spatial Correlation
H = zeros(Nr, Nt, num_realizations);
for k = 1:num_realizations
    H(:, :, k) = sqrt_R_rx * H_iid(:, :, k) * (sqrt_R_tx.');
end

end
