% STARTUP.M - Automatic Workspace Configuration for Mobile Communication Project
% This script runs automatically whenever MATLAB starts or opens this project directory.

clc;
fprintf('================================================================================\n');
fprintf('  5G MIMO MULTIPLEXING OPTIMIZATION PROJECT (ECL DC 401)\n');
fprintf('  Project Workspace & Search Paths Initialized Successfully.\n');
fprintf('================================================================================\n');

% 1. Add all project subdirectories recursively to MATLAB path
project_root = fileparts(mfilename('fullpath'));
addpath(genpath(project_root));

% 2. Clean OpenGL & Graphics Warning Filters
warning('off', 'MATLAB:opengl:SoftwareRendering');
warning('off', 'MATLAB:print:GraphicsAccelerationHardwareUnavailable');
warning('off', 'MATLAB:prnRenderer:opengl');
warning('off', 'MATLAB:handle_graphics:exceptions:SceneServer');

% 3. Set figure default renderer for high visual fidelity
set(groot, 'defaultFigureRenderer', 'painters');

fprintf('\nAvailable Stage Runners (Click or type command in MATLAB):\n');
fprintf('  >> run(''01_channel_modeling/test_channel_statistics.m'')\n');
fprintf('  >> run(''02_baseline_transceivers/run_baseline_comparison.m'')\n');
fprintf('  >> run(''03_optimization_svd_waterfilling/run_capacity_optimization.m'')\n');
fprintf('  >> run(''04_adaptive_mode_switching/run_adaptive_switching_simulation.m'')\n');
fprintf('  >> run(''05_simulink_and_advanced_receivers/run_sic_simulation.m'')\n');
fprintf('  >> run(''06_master_runner_and_benchmarks/main_benchmark_suite.m'')\n');
fprintf('================================================================================\n\n');
