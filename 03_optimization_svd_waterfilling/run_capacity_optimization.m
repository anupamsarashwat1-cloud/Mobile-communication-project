clear; clc; close all;

root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');

fprintf('=================================================================\n');
fprintf(' STAGE 3: Multiplexing Capacity Optimization (SVD + Water-Filling)\n');
fprintf('=================================================================\n');

Nt = 2;
Nr = 2;
P_total = 1.0;
snr_db_vec = -10:2:30;
num_trials = 5000;
rho_values = [0, 0.5, 0.9];

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% 1. Spectral Efficiency Comparison at rho = 0.5
rho_test = 0.5;
C_wf = zeros(length(snr_db_vec), 1);
C_ep = zeros(length(snr_db_vec), 1);
C_bf = zeros(length(snr_db_vec), 1);
C_siso = zeros(length(snr_db_vec), 1);

fprintf('Running ergodic capacity sweeps for rho = %.1f...\n', rho_test);

for s_idx = 1:length(snr_db_vec)
    snr_db = snr_db_vec(s_idx);
    snr_lin = 10^(snr_db / 10);
    noise_var = P_total / snr_lin;
    
    cap_wf_sum = 0;
    cap_ep_sum = 0;
    cap_bf_sum = 0;
    cap_siso_sum = 0;
    
    for k = 1:num_trials
        % Correlated channel realization
        [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho_test, rho_test, 1);
        s = svd(H);
        sigma_sq = s.^2;
        
        % 1. Water-Filling Capacity
        [P_wf, ~, ~] = water_filling_algorithm(sigma_sq, P_total, noise_var);
        cap_wf = sum(log2(1 + P_wf .* sigma_sq' / noise_var));
        cap_wf_sum = cap_wf_sum + cap_wf;
        
        % 2. Equal Power SVD Capacity (P_i = P_total / Nt)
        P_ep = (P_total / Nt) * ones(size(sigma_sq));
        cap_ep = sum(log2(1 + P_ep .* sigma_sq / noise_var));
        cap_ep_sum = cap_ep_sum + cap_ep;
        
        % 3. Single-Stream Dominant Eigen-Beamforming (Rank-1, all power on sigma_1)
        cap_bf = log2(1 + P_total * sigma_sq(1) / noise_var);
        cap_bf_sum = cap_bf_sum + cap_bf;
        
        % 4. SISO Baseline
        h_siso = (randn + 1j*randn)/sqrt(2);
        cap_siso = log2(1 + P_total * abs(h_siso)^2 / noise_var);
        cap_siso_sum = cap_siso_sum + cap_siso;
    end
    
    C_wf(s_idx) = cap_wf_sum / num_trials;
    C_ep(s_idx) = cap_ep_sum / num_trials;
    C_bf(s_idx) = cap_bf_sum / num_trials;
    C_siso(s_idx) = cap_siso_sum / num_trials;
end

figure('Name', 'Ergodic Capacity Comparison', 'Position', [100, 100, 850, 520]);
plot(snr_db_vec, C_wf, 'r-o', 'LineWidth', 2.2, 'MarkerFaceColor', 'r', 'DisplayName', 'Optimal SVD + Water-Filling (Adaptive Rank)');
hold on;
plot(snr_db_vec, C_ep, 'b--s', 'LineWidth', 1.8, 'MarkerFaceColor', 'b', 'DisplayName', 'SVD + Equal Power Allocation (Fixed Rank-2)');
plot(snr_db_vec, C_bf, 'm-.d', 'LineWidth', 1.8, 'MarkerFaceColor', 'm', 'DisplayName', 'Dominant Eigenmode Beamforming (Rank-1)');
plot(snr_db_vec, C_siso, 'k:', 'LineWidth', 1.6, 'DisplayName', 'SISO Rayleigh Baseline (1x1)');

grid on;
xlabel('Average SNR (dB)');
ylabel('Ergodic Spectral Efficiency (bps/Hz)');
title(sprintf('Fixed 2x2 MIMO Ergodic Capacity: Water-Filling Optimization (\\rho = %.1f)', rho_test));
legend('Location', 'northwest', 'FontSize', 10);
saveas(gcf, fullfile(fig_dir, 'capacity_wf_vs_equal_power.png'));

%% 2. Water-Filling Percentage Gain vs Spatial Correlation Sweep
fprintf('Analyzing capacity gain over correlation sweep...\n');
rho_sweep = 0:0.1:0.9;
snr_low = -4; % Low SNR where WF shines
gain_low_snr = zeros(length(rho_sweep), 1);

for r_idx = 1:length(rho_sweep)
    rho = rho_sweep(r_idx);
    noise_var = P_total / (10^(snr_low / 10));
    
    cap_wf_accum = 0;
    cap_ep_accum = 0;
    
    for k = 1:num_trials
        [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 1);
        s = svd(H);
        sigma_sq = s.^2;
        
        [P_wf, ~, ~] = water_filling_algorithm(sigma_sq, P_total, noise_var);
        cap_wf_accum = cap_wf_accum + sum(log2(1 + P_wf .* sigma_sq' / noise_var));
        
        P_ep = (P_total / Nt) * ones(size(sigma_sq));
        cap_ep_accum = cap_ep_accum + sum(log2(1 + P_ep .* sigma_sq / noise_var));
    end
    
    gain_low_snr(r_idx) = ((cap_wf_accum - cap_ep_accum) / cap_ep_accum) * 100;
end

figure('Name', 'Water-Filling Optimization Gain vs Correlation', 'Position', [150, 150, 750, 480]);
bar(rho_sweep, gain_low_snr, 0.5, 'FaceColor', [0.2 0.6 0.8]);
grid on;
xlabel('Spatial Correlation Coefficient (\rho)');
ylabel('Capacity Gain of Water-Filling over Equal Power (%)');
title(sprintf('Water-Filling Optimization Advantage in Fixed 2x2 MIMO (SNR = %d dB)', snr_low));
saveas(gcf, fullfile(fig_dir, 'capacity_gain_vs_correlation.png'));

fprintf('[Stage 3 Complete] Plots saved to 03_optimization_svd_waterfilling/figures/\n');
