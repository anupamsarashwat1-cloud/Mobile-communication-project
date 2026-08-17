function generate_simulink_block_diagram_figure()
% GENERATE_SIMULINK_BLOCK_DIAGRAM_FIGURE
% Creates a high-resolution visual block diagram representing the end-to-end
% 5G MIMO Simulink System Architecture with scopes and diagnostics.

    hFig = figure('Name', '5G MIMO Simulink Architecture', ...
                  'Position', [100, 100, 1100, 520], 'Color', [1 1 1]);
    ax = axes('Position', [0.02, 0.02, 0.96, 0.96]);
    hold(ax, 'on');
    axis(ax, [0 100 0 50]);
    axis(ax, 'off');

    % Subsystem Background Panels
    % 1. Transmitter
    rectangle('Position', [3, 6, 26, 38], 'Curvature', 0.15, ...
              'FaceColor', [0.94 0.96 1.0], 'EdgeColor', [0.3 0.5 0.85], 'LineWidth', 1.8);
    text(16, 41, 'TRANSMITTER SUBSYSTEM', 'FontSize', 11, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Color', [0.1 0.25 0.6]);

    % Tx Blocks
    draw_block(5, 27, 22, 9, [0.85 0.92 1.0], {'Bernoulli Binary', 'Generator (Ts=1µs)'}, [0.1 0.2 0.5]);
    draw_block(5, 12, 22, 9, [0.85 0.92 1.0], {'M-QAM Modulator', '& SVD/STBC Precoder'}, [0.1 0.2 0.5]);
    draw_arrow(16, 27, 16, 21);

    % Tx Antennas
    draw_antenna(29, 18, 'Tx1');
    draw_antenna(29, 12, 'Tx2');
    draw_arrow(27, 18, 29, 18);
    draw_arrow(27, 12, 29, 12);

    % 2. Channel
    rectangle('Position', [37, 8, 26, 34], 'Curvature', 0.15, ...
              'FaceColor', [1.0 0.95 0.92], 'EdgeColor', [0.85 0.45 0.2], 'LineWidth', 1.8);
    text(50, 39, '5G MIMO WIRELESS CHANNEL', 'FontSize', 11, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Color', [0.6 0.2 0.05]);

    draw_block(39, 23, 22, 10, [1.0 0.9 0.82], {'Correlated Rayleigh Fading', 'Channel Matrix (H)'}, [0.6 0.2 0.05]);
    draw_block(39, 10, 22, 8, [1.0 0.9 0.82], {'AWGN Noise Source', '(\sigma_n^2 I)'}, [0.6 0.2 0.05]);

    draw_arrow(31, 18, 39, 27);
    draw_arrow(31, 12, 39, 24);
    draw_arrow(50, 18, 50, 23);

    % Rx Antennas
    draw_antenna(68, 27, 'Rx1');
    draw_antenna(68, 24, 'Rx2');
    draw_arrow(61, 28, 68, 28);
    draw_arrow(61, 24, 68, 24);

    % 3. Receiver
    rectangle('Position', [73, 6, 24, 38], 'Curvature', 0.15, ...
              'FaceColor', [0.93 0.98 0.93], 'EdgeColor', [0.25 0.7 0.35], 'LineWidth', 1.8);
    text(85, 41, 'RECEIVER SUBSYSTEM', 'FontSize', 11, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Color', [0.08 0.45 0.15]);

    draw_block(74, 25, 22, 11, [0.85 0.95 0.85], {'Equalizer / MMSE-SIC', 'Detector (V-BLAST)'}, [0.08 0.45 0.15]);
    draw_block(74, 11, 22, 9, [0.85 0.95 0.85], {'QAM Demodulator', '& Bit Recovery'}, [0.08 0.45 0.15]);

    draw_arrow(70, 27, 74, 28);
    draw_arrow(70, 24, 74, 26);
    draw_arrow(85, 25, 85, 20);

    % 4. Real-time Diagnostic Instruments (Scopes)
    rectangle('Position', [40, 2, 20, 5], 'Curvature', 0.2, ...
              'FaceColor', [0.95 0.95 0.95], 'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1.2);
    text(50, 4.5, 'Constellation Scope & BER Meter', 'FontSize', 9, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Color', [0.2 0.2 0.2]);

    draw_arrow(84, 11, 60, 4.5);

    % Save figure
    this_dir = fileparts(mfilename('fullpath'));
    figures_dir = fullfile(this_dir, 'figures');
    if ~exist(figures_dir, 'dir')
        mkdir(figures_dir);
    end
    save_path = fullfile(figures_dir, 'simulink_model_overview.png');
    saveas(hFig, save_path);
    fprintf('[Success] Generated and saved Simulink architecture diagram: %s\n', save_path);
end

function draw_block(x, y, w, h, faceColor, labelText, textColor)
    rectangle('Position', [x, y, w, h], 'Curvature', 0.1, ...
              'FaceColor', faceColor, 'EdgeColor', faceColor * 0.7, 'LineWidth', 1.2);
    text(x + w/2, y + h/2, labelText, 'FontSize', 9.5, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', textColor, ...
         'Interpreter', 'none');
end

function draw_arrow(x1, y1, x2, y2)
    annotation('arrow', [(x1*0.96+2)/100, (x2*0.96+2)/100], ...
                        [(y1*0.96+2)/50,  (y2*0.96+2)/50], ...
               'Color', [0.3 0.35 0.4], 'LineWidth', 1.4, 'HeadWidth', 7, 'HeadLength', 7);
end

function draw_antenna(x, y, label)
    plot([x, x+1.5], [y, y], 'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
    plot([x+1.5, x+1.5], [y-1.5, y+1.5], 'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
    plot([x+1.5, x+3], [y+1.5, y+1.5], 'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
    plot([x+1.5, x+3], [y-1.5, y-1.5], 'Color', [0.2 0.2 0.2], 'LineWidth', 1.5);
    text(x+3.5, y, label, 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
end
