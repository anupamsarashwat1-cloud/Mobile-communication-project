clear; clc; close all;

% Add all stage subdirectories to MATLAB search path
root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');

fprintf('================================================================================\n');
fprintf(' MIMO SCALING ANALYSIS: 1x1 (SISO) vs 2x2 vs 4x4 vs 8x8 FIXED CONFIGURATIONS\n');
fprintf(' Course: ECL DC 401 - Mobile Communication | Spatial Correlation rho = 0.3\n');
fprintf('================================================================================\n\n');

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% Configuration
mimo_sizes = [1, 2, 4, 8];
labels = {'1x1 (SISO)', '2x2 MIMO', '4x4 MIMO', '8x8 MIMO'};
colors = {'g', 'c', 'r', 'm'};
markers = {'^', 'o', 's', 'd'};
line_styles = {':', '-', '--', '-.'};

rho = 0.3;
P_total = 1.0;
mod_order = 4; % QPSK (k = 2 bits/sym)
k_bits = log2(mod_order);

snr_vec = 0:2:24;
num_cap_trials = 1000;
num_packets = 100;
packet_len = 500;
num_frames = 100;
frame_len = 128;

C_wf_all      = zeros(length(mimo_sizes), length(snr_vec));
ber_mmse_all  = zeros(length(mimo_sizes), length(snr_vec));
goodput_all   = zeros(length(mimo_sizes), length(snr_vec));
median_kappa  = zeros(length(mimo_sizes), 1);

for m_idx = 1:length(mimo_sizes)
    N = mimo_sizes(m_idx);
    Nt = N; Nr = N;
    fprintf('[%d/%d] Simulating %dx%d configuration (rho = %.1f)...\n', m_idx, length(mimo_sizes), Nt, Nr, rho);
    
    % 1. Channel Conditioning Statistics
    [H_batch, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 2000);
    kappas = zeros(2000, 1);
    for t = 1:2000
        kappas(t) = cond(H_batch(:, :, t));
    end
    median_kappa(m_idx) = median(kappas);
    
    % 2. SNR Sweeps (Capacity, BER, Goodput)
    for s_idx = 1:length(snr_vec)
        snr_db = snr_vec(s_idx);
        snr_lin = 10^(snr_db / 10);
        noise_var = P_total / snr_lin;
        
        % --- (a) Ergodic Capacity with SVD + Water-Filling ---
        cap_sum = 0;
        for t = 1:num_cap_trials
            [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 1);
            sigma_sq = svd(H).^2;
            [P_wf, ~, ~] = water_filling_algorithm(sigma_sq, P_total, noise_var);
            cap_sum = cap_sum + sum(log2(1 + P_wf .* sigma_sq.' / noise_var));
        end
        C_wf_all(m_idx, s_idx) = cap_sum / num_cap_trials;
        
        % --- (b) Spatial Multiplexing BER (Linear MMSE) ---
        err_bits = 0;
        total_bits = 0;
        for p = 1:num_packets
            tx_bits = randi([0, 1], Nt, packet_len * k_bits);
            tx_syms = zeros(Nt, packet_len);
            for tx = 1:Nt
                tx_syms(tx, :) = modulate_qam(tx_bits(tx, :).', mod_order).';
            end
            X = tx_syms / sqrt(Nt);
            [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 1);
            N_awgn = sqrt(noise_var / 2) * (randn(Nr, packet_len) + 1j * randn(Nr, packet_len));
            Y = H * X + N_awgn;
            
            W_mmse = (H' * H + (noise_var * Nt) * eye(Nt)) \ H';
            S_hat = sqrt(Nt) * (W_mmse * Y);
            
            rx_bits = zeros(Nt, packet_len * k_bits);
            for tx = 1:Nt
                rx_bits(tx, :) = demodulate_qam(S_hat(tx, :).', mod_order).';
            end
            err_bits = err_bits + sum(sum(tx_bits ~= rx_bits));
            total_bits = total_bits + numel(tx_bits);
        end
        ber_mmse_all(m_idx, s_idx) = max(err_bits / total_bits, 1e-6);
        
        % --- (c) Effective Goodput (bps/Hz) ---
        ok_frames = 0;
        for f = 1:num_frames
            tx_bits = randi([0, 1], Nt, frame_len * k_bits);
            tx_syms = zeros(Nt, frame_len);
            for tx = 1:Nt
                tx_syms(tx, :) = modulate_qam(tx_bits(tx, :).', mod_order).';
            end
            X = tx_syms / sqrt(Nt);
            [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 1);
            N_awgn = sqrt(noise_var / 2) * (randn(Nr, frame_len) + 1j * randn(Nr, frame_len));
            Y = H * X + N_awgn;
            
            W_mmse = (H' * H + (noise_var * Nt) * eye(Nt)) \ H';
            S_hat = sqrt(Nt) * (W_mmse * Y);
            
            rx_bits = zeros(Nt, frame_len * k_bits);
            for tx = 1:Nt
                rx_bits(tx, :) = demodulate_qam(S_hat(tx, :).', mod_order).';
            end
            if sum(sum(tx_bits ~= rx_bits)) == 0
                ok_frames = ok_frames + 1;
            end
        end
        goodput_all(m_idx, s_idx) = Nt * k_bits * (ok_frames / num_frames);
    end
end

%% Generate 4-Panel MIMO Scaling Comparison Figure
figure('Name', 'MIMO Antenna Scaling Comparison', 'Position', [80, 80, 1150, 760]);

% Panel (a): Ergodic Capacity vs SNR
subplot(2, 2, 1);
for m_idx = 1:length(mimo_sizes)
    plot(snr_vec, C_wf_all(m_idx, :), [colors{m_idx}, line_styles{m_idx}, markers{m_idx}], ...
        'LineWidth', 1.9, 'MarkerSize', 5, 'DisplayName', [labels{m_idx}, ' (SVD-WF)']);
    hold on;
end
grid on;
xlabel('Average SNR (dB)');
ylabel('Ergodic Capacity (bps/Hz)');
title('(a) Ergodic Spectral Efficiency Scaling (SVD + Water-Filling)');
legend('Location', 'northwest', 'FontSize', 8);

% Panel (b): MMSE Spatial Multiplexing BER vs SNR
subplot(2, 2, 2);
for m_idx = 1:length(mimo_sizes)
    semilogy(snr_vec, ber_mmse_all(m_idx, :), [colors{m_idx}, line_styles{m_idx}, markers{m_idx}], ...
        'LineWidth', 1.9, 'MarkerSize', 5, 'DisplayName', [labels{m_idx}, ' (MMSE SM)']);
    hold on;
end
grid on;
ylim([1e-5, 1]);
xlabel('Average SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('(b) Spatial Multiplexing BER Scaling (QPSK, MMSE)');
legend('Location', 'southwest', 'FontSize', 8);

% Panel (c): Effective Goodput Scaling vs SNR
subplot(2, 2, 3);
for m_idx = 1:length(mimo_sizes)
    plot(snr_vec, goodput_all(m_idx, :), [colors{m_idx}, line_styles{m_idx}, markers{m_idx}], ...
        'LineWidth', 2.0, 'MarkerSize', 5, 'DisplayName', sprintf('%s (Peak %d bps/Hz)', labels{m_idx}, mimo_sizes(m_idx)*k_bits));
    hold on;
end
grid on;
xlabel('Average SNR (dB)');
ylabel('Effective Goodput (bps/Hz)');
title('(c) Effective Goodput Scaling (QPSK, 128-sym Frames)');
legend('Location', 'northwest', 'FontSize', 8);

% Panel (d): Zheng-Tse DMT Bounds & Channel Conditioning
subplot(2, 2, 4);
for m_idx = 1:length(mimo_sizes)
    N = mimo_sizes(m_idx);
    r_vals = 0:N;
    d_vals = (N - r_vals).^2;
    plot(r_vals, d_vals, [colors{m_idx}, line_styles{m_idx}, markers{m_idx}], ...
        'LineWidth', 2.0, 'MarkerSize', 6, 'DisplayName', sprintf('%s: d^*(r)=(%d-r)^2', labels{m_idx}, N));
    hold on;
end
grid on;
xlim([-0.2, 8.4]);
ylim([-1, 68]);
xlabel('Spatial Multiplexing Gain (r)');
ylabel('Diversity Gain (d)');
title('(d) Zheng-Tse Optimal DMT Bounds (1x1 to 8x8)');
legend('Location', 'northeast', 'FontSize', 8);

sgtitle(sprintf('Impact of Scaling Fixed MIMO Dimensions (1x1 vs 2x2 vs 4x4 vs 8x8, \\rho = %.1f)', rho), ...
    'FontSize', 13, 'FontWeight', 'bold');
saveas(gcf, fullfile(fig_dir, 'mimo_scaling_comparison.png'));

%% Print Terminal Summary Table
idx12 = find(snr_vec == 12, 1);
idx20 = find(snr_vec == 20, 1);
idx24 = find(snr_vec == 24, 1);

fprintf('\n========================================================================================\n');
fprintf('                      MIMO ANTENNA SCALING BENCHMARK SUMMARY (rho = %.1f)\n', rho);
fprintf('========================================================================================\n');
fprintf('%-12s | %-13s | %-12s | %-12s | %-14s | %-12s\n', ...
    'MIMO Config', 'Median kappa', 'BER @ 12dB', 'BER @ 20dB', 'Goodput @ 24dB', 'Cap @ 20dB');
fprintf('----------------------------------------------------------------------------------------\n');
for m_idx = 1:length(mimo_sizes)
    fprintf('%-12s | %-13.2f | %-12.2e | %-12.2e | %-14.2f | %-12.2f\n', ...
        labels{m_idx}, median_kappa(m_idx), ber_mmse_all(m_idx, idx12), ber_mmse_all(m_idx, idx20), ...
        goodput_all(m_idx, idx24), C_wf_all(m_idx, idx20));
end
fprintf('========================================================================================\n');
fprintf('Plot saved to: 06_master_runner_and_benchmarks/figures/mimo_scaling_comparison.png\n');
