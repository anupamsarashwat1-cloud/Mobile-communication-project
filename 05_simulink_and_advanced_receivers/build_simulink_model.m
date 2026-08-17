% BUILD_SIMULINK_MODEL
% Programmatically generates or initializes the Simulink testbench parameters
% for the 2x2 MIMO Diversity & Spatial Multiplexing Optimization System.

clear; clc;

fprintf('=================================================================\n');
fprintf(' STAGE 5: Simulink Testbench Initialization & Configuration\n');
fprintf('=================================================================\n');

% Set model parameters in workspace
modelName = 'mimo_optimization_system';

% Baseband & Signal Parameters
M = 4;                 % QPSK Modulation
k = log2(M);           % Bits per symbol
bitRate = 2e6;         % 2 Mbps
symbolRate = bitRate/k;% 1 Msps
sampleTime = 1/symbolRate;
samplesPerFrame = 100;

% Channel Parameters
EbNo_dB = 12;
SNR_dB = EbNo_dB + 10*log10(k);
rho_spatial = 0.3;

% Pre-calculate correlation matrices
[~, R_tx, R_rx] = generate_correlated_channel(2, 2, rho_spatial, rho_spatial, 1);

fprintf('Model configuration parameters initialized successfully:\n');
fprintf('  Modulation:       QPSK (M=%d)\n', M);
fprintf('  Symbol Rate:      %.1f Msps\n', symbolRate/1e6);
fprintf('  Target SNR:       %.1f dB\n', SNR_dB);
fprintf('  Correlation rho:  %.2f\n', rho_spatial);
fprintf('\nTo open the Simulink model, execute:\n  open_system(''%s'')\n', modelName);
