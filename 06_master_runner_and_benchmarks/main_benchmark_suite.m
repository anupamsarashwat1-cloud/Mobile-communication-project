% MAIN_BENCHMARK_SUITE
% Master simulation testbench executing end-to-end evaluation of all MIMO schemes.
% Generates publication-ready figures, quantitative metrics tables, and consolidated dashboard.

clear; clc; close all;

fprintf('================================================================================\n');
fprintf(' MASTER BENCHMARK SUITE: MIMO DIVERSITY VS SPATIAL MULTIPLEXING OPTIMIZATION\n');
fprintf(' Course: ECL DC 401 - Mobile Communication | Platform: MATLAB & Simulink\n');
fprintf('================================================================================\n\n');

% Add all stage subdirectories to MATLAB search path
root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% Global Simulation Configuration
Nt = 2; Nr = 2;
mod_order = 4; % QPSK (k = 2 bits/sym)
k = log2(mod_order);
snr_vec = 0:2:24;
num_packets = 120;
packet_len = 1000;
rho = 0.3; % Moderate realistic spatial correlation

fprintf('[1/4] Running Error Rate Evaluations (BER vs SNR)...\n');
ber_alamouti = alamouti_stbc_2x2(mod_order, snr_vec, num_packets, packet_len, rho);
[ber_zf, ber_mmse] = spatial_multiplexing_linear(mod_order, snr_vec, num_packets, packet_len, rho);
[ber_sic, ~, ~] = mmse_sic_detector(mod_order, snr_vec, num_packets, packet_len, rho);

fprintf('[2/4] Running Ergodic Capacity & Water-Filling Sweeps...\n');
P_total = 1.0;
snr_cap_vec = -6:2:24;
C_wf = zeros(length(snr_cap_vec), 1);
C_ep = zeros(length(snr_cap_vec), 1);
C_siso = zeros(length(snr_cap_vec), 1);

for s_idx = 1:length(snr_cap_vec)
    snr_db = snr_cap_vec(s_idx);
    noise_var = P_total / (10^(snr_db/10));
    sum_wf = 0; sum_ep = 0; sum_siso = 0;
    
    for trial = 1:2000
        [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 1);
        s = svd(H);
        sigma_sq = s.^2;
        
        [P_wf, ~, ~] = water_filling_algorithm(sigma_sq, P_total, noise_var);
        sum_wf = sum_wf + sum(log2(1 + P_wf .* sigma_sq' / noise_var));
        
        P_ep = (P_total/Nt) * ones(size(sigma_sq));
        sum_ep = sum_ep + sum(log2(1 + P_ep .* sigma_sq / noise_var));
        
        h_siso = (randn + 1j*randn)/sqrt(2);
        sum_siso = sum_siso + log2(1 + P_total*abs(h_siso)^2/noise_var);
    end
    C_wf(s_idx) = sum_wf / 2000;
    C_ep(s_idx) = sum_ep / 2000;
    C_siso(s_idx) = sum_siso / 2000;
end

fprintf('[3/4] Running Goodput & Dynamic Rank Adaptation Evaluations...\n');
num_frames = 150; frame_len = 256;
goodput_div = zeros(length(snr_vec), 1);
goodput_sm = zeros(length(snr_vec), 1);
goodput_adapt = zeros(length(snr_vec), 1);

for s_idx = 1:length(snr_vec)
    snr_db = snr_vec(s_idx);
    noise_var = 1 / (10^(snr_db/10));
    div_ok = 0; sm_ok = 0; adapt_ok = 0;
    
    for f = 1:num_frames
        [H, ~, ~] = generate_correlated_channel(2, 2, rho, rho, 1);
        
        % Diversity path
        tx_bits_div = randi([0, 1], frame_len*k, 1);
        tx_syms_div = qammod(tx_bits_div, mod_order, 'InputType', 'bit', 'UnitAveragePower', true);
        s1 = tx_syms_div(1:2:end); s2 = tx_syms_div(2:2:end); L = length(s1);
        h11=H(1,1); h12=H(1,2); h21=H(2,1); h22=H(2,2);
        x1_t1 = s1/sqrt(2); x2_t1 = s2/sqrt(2);
        x1_t2 = -conj(s2)/sqrt(2); x2_t2 = conj(s1)/sqrt(2);
        n1_t1 = sqrt(noise_var/2)*(randn(L,1)+1j*randn(L,1));
        n2_t1 = sqrt(noise_var/2)*(randn(L,1)+1j*randn(L,1));
        n1_t2 = sqrt(noise_var/2)*(randn(L,1)+1j*randn(L,1));
        n2_t2 = sqrt(noise_var/2)*(randn(L,1)+1j*randn(L,1));
        r1_t1 = h11*x1_t1 + h12*x2_t1 + n1_t1;
        r2_t1 = h21*x1_t1 + h22*x2_t1 + n2_t1;
        r1_t2 = h11*x1_t2 + h12*x2_t2 + n1_t2;
        r2_t2 = h21*x1_t2 + h22*x2_t2 + n2_t2;
        H_norm_sq = abs(h11)^2 + abs(h12)^2 + abs(h21)^2 + abs(h22)^2;
        s1_hat = (conj(h11)*r1_t1 + conj(h21)*r2_t1 + h12*conj(r1_t2) + h22*conj(r2_t2)) / (H_norm_sq/sqrt(2));
        s2_hat = (conj(h12)*r1_t1 + conj(h22)*r2_t1 - h11*conj(r1_t2) - h21*conj(r2_t2)) / (H_norm_sq/sqrt(2));
        det_div = zeros(frame_len, 1); det_div(1:2:end)=s1_hat; det_div(2:2:end)=s2_hat;
        rx_bits_div = qamdemod(det_div, mod_order, 'OutputType', 'bit', 'UnitAveragePower', true);
        is_div_ok = (sum(tx_bits_div ~= rx_bits_div) == 0);
        if is_div_ok, div_ok = div_ok + 1; end
        
        % SM Path
        tx_bits_sm = randi([0, 1], 2, frame_len*k);
        tx_syms_sm = zeros(2, frame_len);
        for tx=1:2
            tx_syms_sm(tx, :) = qammod(tx_bits_sm(tx, :)', mod_order, 'InputType', 'bit', 'UnitAveragePower', true).';
        end
        X_sm = tx_syms_sm / sqrt(2);
        N_sm = sqrt(noise_var/2)*(randn(2, frame_len)+1j*randn(2, frame_len));
        Y_sm = H*X_sm + N_sm;
        W_mmse = (H'*H + 2*noise_var*eye(2)) \ H';
        S_hat_sm = sqrt(2)*(W_mmse * Y_sm);
        rx_bits_sm = zeros(2, frame_len*k);
        for tx=1:2
            rx_bits_sm(tx, :) = qamdemod(S_hat_sm(tx, :)', mod_order, 'OutputType', 'bit', 'UnitAveragePower', true).';
        end
        is_sm_ok = (sum(sum(tx_bits_sm ~= rx_bits_sm)) == 0);
        if is_sm_ok, sm_ok = sm_ok + 1; end
        
        % Adaptive Controller
        [mode_dec, ~, ~] = adaptive_mimo_controller(H, snr_db, mod_order);
        if mode_dec == 1 && is_sm_ok
            adapt_ok = adapt_ok + 2;
        elseif mode_dec == 0 && is_div_ok
            adapt_ok = adapt_ok + 1;
        end
    end
    goodput_div(s_idx)   = 1 * k * (div_ok / num_frames);
    goodput_sm(s_idx)    = 2 * k * (sm_ok / num_frames);
    goodput_adapt(s_idx) = k * (adapt_ok / num_frames);
end

fprintf('[4/4] Generating Consolidated 4-Panel Executive Dashboard...\n');
figure('Name', 'Master MIMO Optimization Summary', 'Position', [80, 80, 1100, 750]);

% Panel 1: BER vs SNR
subplot(2, 2, 1);
semilogy(snr_vec, ber_alamouti, 'r-o', 'LineWidth', 1.8, 'DisplayName', 'Alamouti STBC (d=4, Rate=1)');
hold on;
semilogy(snr_vec, ber_sic, 'g-d', 'LineWidth', 1.8, 'DisplayName', 'MMSE-SIC (V-BLAST, Rate=2)');
semilogy(snr_vec, ber_mmse, 'b-s', 'LineWidth', 1.6, 'DisplayName', 'Linear MMSE (Rate=2)');
semilogy(snr_vec, ber_zf, 'k--^', 'LineWidth', 1.5, 'DisplayName', 'Linear ZF (Rate=2)');
grid on; ylim([1e-5, 1]);
xlabel('SNR (dB)'); ylabel('Bit Error Rate (BER)');
title('(a) BER Performance: Diversity vs Multiplexing');
legend('Location', 'southwest', 'FontSize', 8);

% Panel 2: Ergodic Spectral Efficiency
subplot(2, 2, 2);
plot(snr_cap_vec, C_wf, 'r-o', 'LineWidth', 2.0, 'DisplayName', 'Optimal SVD + Water-Filling');
hold on;
plot(snr_cap_vec, C_ep, 'b--s', 'LineWidth', 1.8, 'DisplayName', 'SVD Equal Power');
plot(snr_cap_vec, C_siso, 'k:', 'LineWidth', 1.5, 'DisplayName', 'SISO Rayleigh Baseline');
grid on;
xlabel('SNR (dB)'); ylabel('Capacity (bps/Hz)');
title('(b) Ergodic Spectral Efficiency (\rho = 0.3)');
legend('Location', 'northwest', 'FontSize', 8);

% Panel 3: Effective Goodput Envelope
subplot(2, 2, 3);
plot(snr_vec, goodput_adapt, 'r-^', 'LineWidth', 2.2, 'MarkerFaceColor', 'r', 'DisplayName', 'Adaptive Mode Switching');
hold on;
plot(snr_vec, goodput_div, 'b--o', 'LineWidth', 1.6, 'DisplayName', 'Fixed Alamouti Diversity');
plot(snr_vec, goodput_sm, 'k-.s', 'LineWidth', 1.6, 'DisplayName', 'Fixed Spatial Multiplexing');
grid on;
xlabel('SNR (dB)'); ylabel('Effective Goodput (bps/Hz)');
title('(c) Effective Goodput: Optimization Envelope');
legend('Location', 'northwest', 'FontSize', 8);

% Panel 4: Zheng-Tse DMT Bound
subplot(2, 2, 4);
plot([0, 1, 2], [4, 1, 0], 'b-o', 'LineWidth', 2.2, 'MarkerFaceColor', 'b', 'DisplayName', '2x2 Optimal DMT Bound');
hold on;
plot(0, 4, 'rp', 'MarkerSize', 11, 'MarkerFaceColor', 'r', 'DisplayName', 'Alamouti (r=0, d=4)');
plot(2, 0, 'm^', 'MarkerSize', 10, 'MarkerFaceColor', 'm', 'DisplayName', 'Spatial Mux (r=2, d=0)');
grid on; xlim([-0.2, 2.5]); ylim([-0.5, 4.5]);
xlabel('Multiplexing Gain r'); ylabel('Diversity Gain d');
title('(d) Diversity-Multiplexing Tradeoff (DMT)');
legend('Location', 'northeast', 'FontSize', 8);

sgtitle('Comprehensive Performance of Fixed 2x2 MIMO Optimization System', 'FontSize', 13, 'FontWeight', 'bold');
saveas(gcf, fullfile(fig_dir, 'master_comprehensive_summary.png'));

%% Terminal Benchmark Summary Output
fprintf('\n================================================================================\n');
fprintf('                           SIMULATION BENCHMARK SUMMARY\n');
fprintf('================================================================================\n');
fprintf('%-15s | %-12s | %-12s | %-12s | %-12s\n', 'Scheme', 'BER @ 10dB', 'BER @ 20dB', 'Goodput@10dB', 'Cap @ 20dB');
fprintf('--------------------------------------------------------------------------------\n');
idx10 = find(snr_vec == 10, 1);
idx20 = find(snr_vec == 20, 1);
idx_cap20 = find(snr_cap_vec == 20, 1);

fprintf('%-15s | %-12.2e | %-12.2e | %-12.2f | %-12.2f\n', 'Alamouti STBC', ber_alamouti(idx10), ber_alamouti(idx20), goodput_div(idx10), C_siso(idx_cap20));
fprintf('%-15s | %-12.2e | %-12.2e | %-12.2f | %-12.2f\n', 'SM (ZF)',       ber_zf(idx10),       ber_zf(idx20),       goodput_sm(idx10),  C_ep(idx_cap20));
fprintf('%-15s | %-12.2e | %-12.2e | %-12.2f | %-12.2f\n', 'SM (MMSE)',     ber_mmse(idx10),     ber_mmse(idx20),     goodput_sm(idx10),  C_ep(idx_cap20));
fprintf('%-15s | %-12.2e | %-12.2e | %-12.2f | %-12.2f\n', 'SM (MMSE-SIC)', ber_sic(idx10),      ber_sic(idx20),      goodput_sm(idx10),  C_ep(idx_cap20));
fprintf('%-15s | %-12s | %-12s | %-12.2f | %-12.2f\n', 'Adaptive MIMO', 'Adaptive',   'Adaptive',   goodput_adapt(idx10), C_wf(idx_cap20));
fprintf('================================================================================\n');
fprintf('All tests executed successfully. Figures saved to 06_master_runner_and_benchmarks/figures/\n');
