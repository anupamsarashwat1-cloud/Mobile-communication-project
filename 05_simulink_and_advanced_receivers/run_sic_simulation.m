clear; clc; close all;

root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');

fprintf('=================================================================\n');
fprintf(' STAGE 5: Advanced Receivers (MMSE-SIC / V-BLAST Detection)\n');
fprintf('=================================================================\n');

mod_order = 4; % QPSK
snr_db_vec = 0:2:24;
num_packets = 150;
packet_len = 1000;
rho = 0.3; % Moderate correlation

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fprintf('Simulating MMSE-SIC, MMSE, and ZF detectors over 2x2 MIMO (rho = %.1f)...\n', rho);
[ber_sic, ber_mmse, ber_zf] = mmse_sic_detector(mod_order, snr_db_vec, num_packets, packet_len, rho);

figure('Name', 'MMSE-SIC vs Linear Detectors', 'Position', [100, 100, 800, 520]);
semilogy(snr_db_vec, ber_zf, 'k--^', 'LineWidth', 1.8, 'MarkerFaceColor', 'k', 'DisplayName', 'Linear Zero-Forcing (ZF)');
hold on;
semilogy(snr_db_vec, ber_mmse, 'b-s', 'LineWidth', 2.0, 'MarkerFaceColor', 'b', 'DisplayName', 'Linear MMSE');
semilogy(snr_db_vec, ber_sic, 'r-o', 'LineWidth', 2.2, 'MarkerFaceColor', 'r', 'DisplayName', 'Non-Linear MMSE-SIC (V-BLAST)');

grid on;
ylim([1e-5, 1]);
xlabel('Average SNR per Antenna (dB)');
ylabel('Bit Error Rate (BER)');
title(sprintf('Fixed 2x2 MIMO: Non-Linear MMSE-SIC vs Linear Detectors (QPSK, \\rho = %.1f)', rho));
legend('Location', 'southwest', 'FontSize', 10);

saveas(gcf, fullfile(fig_dir, 'sic_vs_linear_receivers_ber.png'));
fprintf('[Stage 5 Complete] Plots saved to 05_simulink_and_advanced_receivers/figures/\n');
