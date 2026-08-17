clear; clc; close all;

root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');

fprintf('=================================================================\n');
fprintf(' STAGE 4: Adaptive Mode Switching & Goodput Optimization\n');
fprintf('=================================================================\n');

mod_order = 4; % QPSK
k = log2(mod_order);
snr_db_vec = -4:2:24;
num_frames = 150;
frame_syms = 256;
rho = 0.4;

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

goodput_div = zeros(length(snr_db_vec), 1);
goodput_sm  = zeros(length(snr_db_vec), 1);
goodput_adapt = zeros(length(snr_db_vec), 1);

fprintf('Running Monte Carlo frame error and goodput simulations...\n');

for s_idx = 1:length(snr_db_vec)
    snr_db = snr_db_vec(s_idx);
    snr_lin = 10^(snr_db / 10);
    noise_var = 1 / snr_lin;
    
    div_frame_success = 0;
    sm_frame_success  = 0;
    adapt_frame_success = 0;
    
    for f = 1:num_frames
        [H, ~, ~] = generate_correlated_channel(2, 2, rho, rho, 1);
        
        % Diversity Mode (Alamouti STBC)
        tx_bits_div = randi([0, 1], frame_syms * k, 1);
        tx_syms_div = modulate_qam(tx_bits_div, mod_order);
        
        s1 = tx_syms_div(1:2:end); s2 = tx_syms_div(2:2:end); L = length(s1);
        h11 = H(1,1); h12 = H(1,2); h21 = H(2,1); h22 = H(2,2);
        
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
        
        det_div = zeros(frame_syms, 1);
        det_div(1:2:end) = s1_hat; det_div(2:2:end) = s2_hat;
        rx_bits_div = demodulate_qam(det_div, mod_order);
        
        is_div_success = (sum(tx_bits_div ~= rx_bits_div) == 0);
        if is_div_success, div_frame_success = div_frame_success + 1; end
        
        % Spatial Multiplexing (MMSE detector)
        tx_bits_sm = randi([0, 1], 2, frame_syms * k);
        tx_syms_sm = zeros(2, frame_syms);
        for tx = 1:2
            tx_syms_sm(tx, :) = modulate_qam(tx_bits_sm(tx, :)', mod_order).';
        end
        X_sm = tx_syms_sm / sqrt(2);
        N_sm = sqrt(noise_var/2)*(randn(2, frame_syms) + 1j*randn(2, frame_syms));
        Y_sm = H * X_sm + N_sm;
        
        W_mmse = (H'*H + 2*noise_var*eye(2)) \ H';
        S_hat_sm = sqrt(2)*(W_mmse * Y_sm);
        
        rx_bits_sm = zeros(2, frame_syms * k);
        for tx = 1:2
            rx_bits_sm(tx, :) = demodulate_qam(S_hat_sm(tx, :)', mod_order).';
        end
        
        is_sm_success = (sum(sum(tx_bits_sm ~= rx_bits_sm)) == 0);
        if is_sm_success, sm_frame_success = sm_frame_success + 1; end
        
        % Adaptive Mode Controller
        [mode_decision, ~, ~] = adaptive_mimo_controller(H, snr_db, mod_order);
        if mode_decision == 1
            if is_sm_success
                adapt_frame_success = adapt_frame_success + 2;
            end
        else
            if is_div_success
                adapt_frame_success = adapt_frame_success + 1;
            end
        end
    end
    
    goodput_div(s_idx)   = 1 * k * (div_frame_success / num_frames);
    goodput_sm(s_idx)    = 2 * k * (sm_frame_success / num_frames);
    goodput_adapt(s_idx) = k * (adapt_frame_success / num_frames);
end

%% Plot Effective Goodput Envelope
figure('Name', 'Effective Goodput Comparison', 'Position', [100, 100, 850, 520]);
plot(snr_db_vec, goodput_adapt, 'r-^', 'LineWidth', 2.4, 'MarkerFaceColor', 'r', 'MarkerSize', 7, 'DisplayName', 'Optimized Adaptive MIMO Switching');
hold on;
plot(snr_db_vec, goodput_div, 'b--o', 'LineWidth', 1.8, 'MarkerFaceColor', 'b', 'DisplayName', 'Fixed Alamouti STBC Diversity (Rank-1)');
plot(snr_db_vec, goodput_sm, 'k-.s', 'LineWidth', 1.8, 'MarkerFaceColor', 'k', 'DisplayName', 'Fixed Spatial Multiplexing (Rank-2 MMSE)');

grid on;
xlabel('Average SNR per Antenna (dB)');
ylabel('Effective Goodput (bps/Hz)');
title(sprintf('Fixed 2x2 MIMO Goodput Optimization: Adaptive Switching vs Fixed Modes (\\rho = %.1f)', rho));
legend('Location', 'northwest', 'FontSize', 10);
saveas(gcf, fullfile(fig_dir, 'effective_goodput_envelope.png'));

%% Plot Decision Region Boundary
kappa_range = linspace(1, 10, 100);
snr_range = linspace(-4, 24, 100);
[KAPPA, SNR_GRID] = meshgrid(kappa_range, snr_range);
DECISION_MAP = double((SNR_GRID >= 8.0) & (KAPPA <= 4.5));

figure('Name', 'Mode Decision Regions', 'Position', [150, 150, 750, 480]);
contourf(KAPPA, SNR_GRID, DECISION_MAP, [0 0.5 1], 'LineColor', 'k');
colormap([0.3 0.6 0.9; 0.9 0.4 0.3]);
xlabel('Channel Condition Number \kappa(H) = \sigma_{max}/\sigma_{min}');
ylabel('Instantaneous SNR (dB)');
title('Adaptive MIMO Switching Decision Regions in Fixed 2x2 Configuration');
text(6.0, 16, 'Diversity Mode (STBC)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
text(2.0, 16, 'Spatial Multiplexing Mode', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
saveas(gcf, fullfile(fig_dir, 'mode_switching_decision_boundary.png'));

fprintf('[Stage 4 Complete] Plots saved to 04_adaptive_mode_switching/figures/\n');
