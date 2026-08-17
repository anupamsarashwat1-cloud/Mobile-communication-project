clear; clc; close all;

root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');

fprintf('=================================================================\n');
fprintf(' STAGE 6: Zheng-Tse Diversity-Multiplexing Tradeoff (DMT) Analysis\n');
fprintf('=================================================================\n');

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% 1. Theoretical DMT Curves for 2x2 and 4x4 MIMO
% Zheng & Tse (2003): d*(r) = (Nt - r) * (Nr - r) for integer r
% Piecewise linear curve connecting integer multiplexing gains r

% 2x2 MIMO
r_2x2 = [0, 1, 2];
d_2x2 = [(2-0)*(2-0), (2-1)*(2-1), (2-2)*(2-2)]; % [4, 1, 0]

% 4x4 MIMO
r_4x4 = [0, 1, 2, 3, 4];
d_4x4 = [(4-0)*(4-0), (4-1)*(4-1), (4-2)*(4-2), (4-3)*(4-3), (4-4)*(4-4)]; % [16, 9, 4, 1, 0]

figure('Name', 'Diversity-Multiplexing Tradeoff (DMT)', 'Position', [100, 100, 850, 520]);

% Plot 2x2 Bound
plot(r_2x2, d_2x2, 'b-o', 'LineWidth', 2.5, 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', '2x2 MIMO Optimal DMT Bound: d^*(r) = (2-r)^2');
hold on;

% Plot 4x4 Bound
plot(r_4x4, d_4x4, 'k--s', 'LineWidth', 2.0, 'MarkerFaceColor', 'k', 'MarkerSize', 7, 'DisplayName', '4x4 MIMO Optimal DMT Bound: d^*(r) = (4-r)^2');

% Operating points for 2x2 Schemes
plot(0, 4, 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'DisplayName', 'Alamouti STBC (r=0, d=4) - Pure Diversity');
plot(1, 1, 'gd', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'DisplayName', 'Rank-1 Beamforming / STBC Rate-1');
plot(2, 0, 'm^', 'MarkerSize', 12, 'MarkerFaceColor', 'm', 'DisplayName', 'Spatial Multiplexing (r=2, d=0) - Max Rate');

grid on;
xlim([-0.2, 4.2]);
ylim([-0.5, 17]);
xlabel('Spatial Multiplexing Gain (r = R / log_2(SNR))', 'FontSize', 11);
ylabel('Diversity Gain (d = -lim log(BER) / log(SNR))', 'FontSize', 11);
title('Diversity-Multiplexing Trade-off (Zheng-Tse Optimal Bound)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 10);

% Annotations
text(0.1, 4.3, 'Alamouti STBC (Full Diversity)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'r');
text(1.7, 0.8, 'Spatial Multiplexing (Full Rate)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'm');

saveas(gcf, fullfile(fig_dir, 'dmt_diversity_multiplexing_curve.png'));
fprintf('[Stage 6 DMT Complete] Plot saved to 06_master_runner_and_benchmarks/figures/\n');
