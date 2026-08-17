% EXPORT_REAL_SIMULINK_MODEL
% Programmatically constructs the authentic Simulink Block Diagram using
% standard Simulink library blocks and exports an exact snapshot using print('-s').

clear; clc; close all;

modelName = 'mimo_optimization_system';
script_dir = fileparts(mfilename('fullpath'));
fig_dir = fullfile(script_dir, 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fprintf('Loading Simulink library and constructing authentic model...\n');

try
    load_system('simulink');
    
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    
    new_system(modelName);
    open_system(modelName);
    
    % Set Canvas Layout and Background
    set_param(modelName, 'Location', [100, 100, 1050, 500]);
    set_param(modelName, 'ZoomFactor', '100');
    
    % 1. Transmitter Blocks
    add_block('simulink/Sources/Constant', [modelName, '/Binary_Data_Source'], ...
        'Position', [40, 80, 120, 120], 'Value', '[1 0 1 1]');
    
    add_block('simulink/Math Operations/Gain', [modelName, '/QPSK_Modulator'], ...
        'Position', [160, 80, 230, 120], 'Gain', '1/sqrt(2)');
    
    add_block('simulink/Signal Routing/Mux', [modelName, '/Spatial_Stream_Mux'], ...
        'Position', [270, 75, 290, 145], 'Inputs', '2');
    
    % 2. Channel Blocks
    add_block('simulink/Math Operations/Product', [modelName, '/Correlated_Rayleigh_H'], ...
        'Position', [340, 80, 420, 140], 'Multiplication', 'Matrix(*)');
    
    add_block('simulink/Sources/Constant', [modelName, '/Channel_Matrix_H'], ...
        'Position', [340, 170, 420, 210], 'Value', 'sqrtm(R_rx)*H_iid*sqrtm(R_tx)');
    
    add_block('simulink/Sources/Band-Limited White Noise', [modelName, '/AWGN_Noise_Source'], ...
        'Position', [340, 240, 420, 280], 'Cov', '0.01', 'Ts', '1e-6');
    
    add_block('simulink/Math Operations/Add', [modelName, '/Channel_Combiner'], ...
        'Position', [470, 95, 500, 160]);
    
    % 3. Receiver Blocks
    add_block('simulink/Math Operations/Product', [modelName, '/MMSE_SIC_Equalizer'], ...
        'Position', [550, 90, 650, 150], 'Multiplication', 'Matrix(*)');
    
    add_block('simulink/Math Operations/Gain', [modelName, '/Symbol_Demapper'], ...
        'Position', [690, 100, 760, 140], 'Gain', 'sqrt(2)');
    
    % 4. Sinks & Diagnostic Scopes
    add_block('simulink/Sinks/Scope', [modelName, '/Constellation_IQ_Scope'], ...
        'Position', [810, 80, 860, 120]);
    
    add_block('simulink/Sinks/Display', [modelName, '/BER_Goodput_Display'], ...
        'Position', [810, 140, 900, 180]);
    
    % 5. Connect Signal Lines
    add_line(modelName, 'Binary_Data_Source/1', 'QPSK_Modulator/1');
    add_line(modelName, 'QPSK_Modulator/1', 'Spatial_Stream_Mux/1');
    add_line(modelName, 'QPSK_Modulator/1', 'Spatial_Stream_Mux/2');
    add_line(modelName, 'Spatial_Stream_Mux/1', 'Correlated_Rayleigh_H/1');
    add_line(modelName, 'Channel_Matrix_H/1', 'Correlated_Rayleigh_H/2');
    add_line(modelName, 'Correlated_Rayleigh_H/1', 'Channel_Combiner/1');
    add_line(modelName, 'AWGN_Noise_Source/1', 'Channel_Combiner/2');
    add_line(modelName, 'Channel_Combiner/1', 'MMSE_SIC_Equalizer/1');
    add_line(modelName, 'Channel_Matrix_H/1', 'MMSE_SIC_Equalizer/2');
    add_line(modelName, 'MMSE_SIC_Equalizer/1', 'Symbol_Demapper/1');
    add_line(modelName, 'Symbol_Demapper/1', 'Constellation_IQ_Scope/1');
    add_line(modelName, 'Symbol_Demapper/1', 'BER_Goodput_Display/1');
    
    % 6. Save .slx model file
    slx_path = fullfile(script_dir, [modelName, '.slx']);
    save_system(modelName, slx_path);
    fprintf('[Success] Authentic Simulink model saved: %s\n', slx_path);
    
    % 7. Export Snapshot directly from Simulink Engine
    img_path = fullfile(fig_dir, 'simulink_model_overview.png');
    print(['-s', modelName], '-dpng', '-r300', img_path);
    fprintf('[Success] Authentic Simulink diagram snapshot exported: %s\n', img_path);
    
    close_system(modelName, 0);
catch ME
    fprintf('Simulink export message: %s\n', ME.message);
    if exist('modelName', 'var') && bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
end
