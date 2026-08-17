clear; clc; close all;

% Add project root to path
root_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root_dir));

% Suppress headless/software OpenGL rendering warnings
warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');

fprintf('=======================================================\n');
fprintf(' STAGE 1: MIMO Channel Modeling & Statistical Analysis\n');
fprintf('=======================================================\n');

% Simulation parameters
Nt = 2;
Nr = 2;
num_trials = 15000;
rho_values = [0, 0.3, 0.6, 0.9];

% Create figures directory if not exists
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% 1. Singular Value Distribution vs Correlation
figure('Name', 'MIMO Singular Values vs Spatial Correlation', 'Position', [100, 100, 900, 500]);
colors = {'b', 'g', 'm', 'r'};

for idx = 1:length(rho_values)
    rho = rho_values(idx);
    [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, num_trials);
    
    sigma1 = zeros(num_trials, 1);
    sigma2 = zeros(num_trials, 1);
    
    for k = 1:num_trials
        s = svd(H(:, :, k));
        sigma1(k) = s(1);
        sigma2(k) = s(2);
    end
    
    subplot(1, 2, 1);
    [f1, x1] = smooth_density(sigma1, 50, 0, 3.5);
    plot(x1, f1, 'Color', colors{idx}, 'LineWidth', 1.8, 'DisplayName', sprintf('\\rho = %.1f (\\sigma_1)', rho));
    hold on;
    grid on;
    xlabel('Singular Value \sigma_1 (Dominant Mode)');
    ylabel('Probability Density Function (PDF)');
    title('Dominant Singular Value (\sigma_1) PDF');
    legend('Location', 'northeast');
    
    subplot(1, 2, 2);
    [f2, x2] = smooth_density(sigma2, 50, 0, 2.0);
    plot(x2, f2, 'Color', colors{idx}, 'LineWidth', 1.8, 'DisplayName', sprintf('\\rho = %.1f (\\sigma_2)', rho));
    hold on;
    grid on;
    xlabel('Singular Value \sigma_2 (Weaker Mode)');
    ylabel('Probability Density Function (PDF)');
    title('Weaker Singular Value (\sigma_2) PDF');
    legend('Location', 'northeast');
end

sgtitle(sprintf('Fixed %dx%d MIMO: Impact of Spatial Correlation on Channel Singular Values', Nt, Nr), 'FontSize', 12, 'FontWeight', 'bold');
saveas(gcf, fullfile(fig_dir, 'singular_value_pdf.png'));

%% 2. Condition Number kappa(H) vs Spatial Correlation Sweep
rho_sweep = 0:0.05:0.95;
mean_cond_num = zeros(length(rho_sweep), 1);
median_cond_num = zeros(length(rho_sweep), 1);
p90_cond_num = zeros(length(rho_sweep), 1);

for i = 1:length(rho_sweep)
    rho = rho_sweep(i);
    [H, ~, ~] = generate_correlated_channel(Nt, Nr, rho, rho, 4000);
    cond_nums = zeros(4000, 1);
    for k = 1:4000
        cond_nums(k) = cond(H(:, :, k));
    end
    mean_cond_num(i) = mean(cond_nums);
    median_cond_num(i) = median(cond_nums);
    p90_cond_num(i) = fast_prctile(cond_nums, 90);
end

figure('Name', 'Condition Number vs Correlation', 'Position', [150, 150, 750, 480]);
plot(rho_sweep, mean_cond_num, 'r-o', 'LineWidth', 2, 'MarkerFaceColor', 'r', 'DisplayName', 'Mean Condition Number');
hold on;
plot(rho_sweep, median_cond_num, 'b-s', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'DisplayName', 'Median Condition Number');
plot(rho_sweep, p90_cond_num, 'k--', 'LineWidth', 1.5, 'DisplayName', '90th Percentile');
grid on;
xlabel('Spatial Correlation Coefficient (\rho)');
ylabel('Channel Condition Number \kappa(H) = \sigma_{max}/\sigma_{min}');
title(sprintf('Ill-Conditioning Growth in Fixed %dx%d MIMO under Spatial Correlation', Nt, Nr));
legend('Location', 'northwest');
saveas(gcf, fullfile(fig_dir, 'condition_number_vs_correlation.png'));

fprintf('[Stage 1 Complete] Plots saved to 01_channel_modeling/figures/\n');
