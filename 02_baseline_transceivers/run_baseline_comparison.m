clear; clc; close all;

root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');

fprintf('=================================================================\n');
fprintf(' STAGE 2: Baseline Comparison (Alamouti STBC vs ZF/MMSE Receivers)\n');
fprintf('=================================================================\n');

% Simulation Parameters
mod_order = 4; % QPSK
snr_db_vec = 0:2:24;
num_packets = 150;
packet_len = 1000;
rho = 0; % Uncorrelated baseline

% Output directories
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fprintf('Simulating Alamouti STBC 2x2 Diversity...\n');
ber_alamouti = alamouti_stbc_2x2(mod_order, snr_db_vec, num_packets, packet_len, rho);

fprintf('Simulating Spatial Multiplexing 2x2 (ZF & MMSE)...\n');
[ber_zf, ber_mmse] = spatial_multiplexing_linear(mod_order, snr_db_vec, num_packets, packet_len, rho);

%% Plot Comparative BER vs SNR
figure('Name', 'BER Comparison: Alamouti STBC vs Spatial Multiplexing', 'Position', [100, 100, 800, 520]);
semilogy(snr_db_vec, ber_alamouti, 'r-o', 'LineWidth', 2, 'MarkerFaceColor', 'r', 'DisplayName', 'Alamouti STBC (2x2, Rate=1 stream, Diversity d=4)');
hold on;
semilogy(snr_db_vec, ber_mmse, 'b-s', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'DisplayName', 'Spatial Multiplexing (2x2 MMSE, Rate=2 streams)');
semilogy(snr_db_vec, ber_zf, 'k--^', 'LineWidth', 1.8, 'MarkerFaceColor', 'k', 'DisplayName', 'Spatial Multiplexing (2x2 ZF, Rate=2 streams)');

grid on;
ylim([1e-5, 1]);
xlabel('Average SNR per Rx Antenna (dB)');
ylabel('Bit Error Rate (BER)');
title(sprintf('Fixed 2x2 MIMO: Diversity vs Spatial Multiplexing (QPSK, \\rho = %.1f)', rho));
legend('Location', 'southwest', 'FontSize', 10);

saveas(gcf, fullfile(fig_dir, 'alamouti_vs_sm_ber.png'));

%% Noise Enhancement Analysis for Zero-Forcing Receiver
H_samples = 10000;
noise_enhancement_zf = zeros(H_samples, 1);
for k = 1:H_samples
    H = (randn(2, 2) + 1j*randn(2, 2)) / sqrt(2);
    W_zf = pinv(H);
    % Noise amplification factor is trace((H^H * H)^(-1))
    noise_enhancement_zf(k) = trace(inv(H' * H));
end

figure('Name', 'ZF Noise Amplification Distribution', 'Position', [150, 150, 700, 450]);
histogram(10*log10(noise_enhancement_zf), 60, 'Normalization', 'pdf', 'FaceColor', [0.85 0.325 0.098]);
grid on;
xlabel('Noise Enhancement Penalty 10\cdotlog_{10}(Tr((H^H H)^{-1})) [dB]');
ylabel('Probability Density Function');
title('Zero-Forcing (ZF) Receiver: Noise Amplification Penalty in 2x2 MIMO');
saveas(gcf, fullfile(fig_dir, 'zf_noise_amplification_analysis.png'));

fprintf('[Stage 2 Complete] Plots saved to 02_baseline_transceivers/figures/\n');
