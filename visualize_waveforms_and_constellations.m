function visualize_waveforms_and_constellations()
% VISUALIZE_WAVEFORMS_AND_CONSTELLATIONS
% Interactive visual demonstration of MIMO Transmitters, Fading Channels,
% Receivers, I/Q Baseband Waveforms, Constellation Scopes, and Water-Filling Tanks.
%
% Designed for ECL DC 401 Mobile Communication Project.

    fprintf('=================================================================\n');
    fprintf(' 5G MIMO WAVEFORM, CONSTELLATION & RECEIVER VISUALIZER\n');
    fprintf('=================================================================\n');
    fprintf('Generating live baseband waveforms, spatial fading, and equalized constellations...\n\n');

    % Add paths
    addpath(fullfile(pwd, 'common'));
    addpath(fullfile(pwd, '01_channel_modeling'));
    addpath(fullfile(pwd, '02_baseline_transceivers'));
    addpath(fullfile(pwd, '03_optimization_svd_waterfilling'));
    addpath(fullfile(pwd, '05_simulink_and_advanced_receivers'));

    % Parameters
    Nt = 2; Nr = 2;
    M = 4; % QPSK modulation
    numSymbols = 1000;
    snr_dB = 12; % 12 dB SNR
    rho = 0.4;   % Spatial correlation

    %% 1. TRANSMITTER: Symbol Generation & QAM Baseband Modulation
    bits = randi([0 1], numSymbols * log2(M), Nt);
    tx_symbols = zeros(numSymbols, Nt);
    for tx = 1:Nt
        tx_symbols(:, tx) = modulate_qam(bits(:, tx), M);
    end

    %% 2. CHANNEL: Spatially Correlated Rayleigh Fading & AWGN Noise
    snr_linear = 10^(snr_dB / 10);
    sigma_n = sqrt(1 / (2 * snr_linear));

    % Generate Kronecker correlated channel matrix
    R_tx = [1, rho; rho, 1];
    R_rx = [1, rho; rho, 1];
    H_iid = (randn(Nr, Nt) + 1j * randn(Nr, Nt)) / sqrt(2);
    H = sqrtm(R_rx) * H_iid * sqrtm(R_tx);

    % Transmit over MIMO Channel
    noise = sigma_n * (randn(Nr, numSymbols) + 1j * randn(Nr, numSymbols));
    rx_signal = H * (tx_symbols.') + noise; % Nr x numSymbols

    %% 3. RECEIVER: Linear ZF, MMSE, and Ordered MMSE-SIC Equalization
    % Zero-Forcing Equalization
    W_zf = pinv(H);
    rx_zf = W_zf * rx_signal;

    % MMSE Equalization
    W_mmse = (H' * H + (2 * sigma_n^2) * eye(Nt)) \ H';
    rx_mmse = W_mmse * rx_signal;

    % SVD Decomposition & Water-Filling Power Allocation
    [U, S, V] = svd(H);
    singular_values = diag(S);
    sigma_sq = singular_values.^2;
    noise_var = 2 * sigma_n^2;
    P_alloc = water_filling_algorithm(sigma_sq, 1.0, noise_var);
    gamma_k = sigma_sq / noise_var;

    %% 4. PLOTTING: 6-Panel Visual Diagnostic Instrument
    hFig = figure('Name', 'MIMO Waveform & Constellation Visualizer', ...
                  'Position', [100, 80, 1100, 750], 'Color', [0.96 0.97 0.98]);

    % Panel 1: Time-Domain Baseband I/Q Waveforms (Transmitter Output)
    subplot(2, 3, 1);
    t_idx = 1:60;
    plot(t_idx, real(tx_symbols(t_idx, 1)), 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4); hold on;
    plot(t_idx, imag(tx_symbols(t_idx, 1)), 'r--s', 'LineWidth', 1.2, 'MarkerSize', 4);
    grid on; box on;
    title('Tx Antenna 1: Baseband Waveform', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Symbol Time Index (k)'); ylabel('Amplitude');
    legend('In-Phase (I)', 'Quadrature (Q)', 'Location', 'northeast');
    ylim([-1.6 1.6]);

    % Panel 2: Received Faded & Noisy Signal Waveforms (Receiver Input)
    subplot(2, 3, 2);
    plot(t_idx, real(rx_signal(1, t_idx)), 'Color', [0.1 0.6 0.2], 'LineWidth', 1.4); hold on;
    plot(t_idx, real(rx_signal(2, t_idx)), 'Color', [0.8 0.4 0.0], 'LineWidth', 1.4);
    grid on; box on;
    title(sprintf('Rx Antennas: Faded Signal (SNR = %d dB)', snr_dB), 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Symbol Time Index (k)'); ylabel('Received Amplitude');
    legend('Rx 1 (Faded)', 'Rx 2 (Faded)', 'Location', 'northeast');

    % Panel 3: Transmitted Clean QPSK Constellation
    subplot(2, 3, 3);
    scatter(real(tx_symbols(:, 1)), imag(tx_symbols(:, 1)), 40, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
    grid on; box on; axis square;
    xlim([-2 2]); ylim([-2 2]);
    title('Transmitter I/Q Constellation', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    line([-2 2], [0 0], 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
    line([0 0], [-2 2], 'Color', [0.5 0.5 0.5], 'LineStyle', ':');

    % Panel 4: Received Faded / Inter-Stream Corrupted Constellation
    subplot(2, 3, 4);
    scatter(real(rx_signal(1, :)), imag(rx_signal(1, :)), 20, [0.85 0.3 0.2], 'filled', 'MarkerFaceAlpha', 0.4);
    grid on; box on; axis square;
    title('Received Un-equalized Constellation', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    xlim([-3.5 3.5]); ylim([-3.5 3.5]);
    line([-3.5 3.5], [0 0], 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
    line([0 0], [-3.5 3.5], 'Color', [0.5 0.5 0.5], 'LineStyle', ':');

    % Panel 5: Recovered Constellation After Linear MMSE Equalization
    subplot(2, 3, 5);
    scatter(real(rx_mmse(1, :)), imag(rx_mmse(1, :)), 25, [0.1 0.7 0.3], 'filled', 'MarkerFaceAlpha', 0.5);
    grid on; box on; axis square;
    xlim([-2.5 2.5]); ylim([-2.5 2.5]);
    title('MMSE Equalized Output (Stream 1)', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
    line([-2.5 2.5], [0 0], 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
    line([0 0], [-2.5 2.5], 'Color', [0.5 0.5 0.5], 'LineStyle', ':');

    % Panel 6: SVD Water-Filling Optimal Power Tank Levels
    subplot(2, 3, 6);
    b = bar(1:Nt, [P_alloc(:), 1./gamma_k(:)], 'stacked');
    b(1).FaceColor = [0.2 0.5 0.8];
    b(2).FaceColor = [0.85 0.85 0.85];
    grid on; box on;
    title('SVD Water-Filling Power Allocation', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Spatial Eigenmode (i)'); ylabel('Power Level / Noise Floor');
    legend('Allocated Power (P_i^*)', 'Inverse SNR Floor (1/\gamma_i)', 'Location', 'northeast');
    set(gca, 'XTick', 1:Nt, 'XTickLabel', {'Mode 1 (\sigma_1)', 'Mode 2 (\sigma_2)'});

    % Export visualization figure
    if ~exist(fullfile(pwd, 'docs', 'figures'), 'dir')
        mkdir(fullfile(pwd, 'docs', 'figures'));
    end
    saveas(hFig, fullfile(pwd, 'docs', 'figures', 'live_waveforms_and_constellations.png'));
    fprintf('[Success] Generated and saved live visualization: docs/figures/live_waveforms_and_constellations.png\n');
end
