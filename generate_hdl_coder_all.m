% =============================================================================
% Script: generate_hdl_coder_all.m
% Project: Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)
% Description: Master automated synthesis script executing MATLAB HDL Coder
%              across all modular baseband kernels to generate synthesizable
%              IEEE 1364-2001 Verilog for SCL 180nm / Cadence gpdk180.
% =============================================================================

clc;
clear;
fprintf('======================================================================\n');
fprintf(' MATLAB HDL CODER AUTOMATED SYNTHESIS PIPELINE: SMVDU-MIMO-180 ASIC\n');
fprintf('======================================================================\n\n');

% Add hardware MATLAB source directory to search path
addpath(fullfile(pwd, 'hdl_src_matlab'));

target_dir = fullfile(pwd, 'hdl_asic', 'build_rtl');
if ~exist(target_dir, 'dir')
    mkdir(target_dir);
end

% 1. Create ASIC-Grade HDL Coder Configuration
cfg = coder.config('hdl');

% Output target and language
cfg.TargetLanguage               = 'Verilog';
cfg.InlineConfigurations         = true;
cfg.GenerateComments             = true;
cfg.TreatRealsInGeneratedCodeAs  = 'None'; % Enable native floating-point / real support

% ASIC Clock and Reset Specification
cfg.ResetType                    = 'Synchronous';
cfg.ResetAssertedLevel           = 'ActiveHigh';
cfg.ClockInputPort               = 'clk';
cfg.ResetInputPort               = 'rst';
cfg.ClockEnableInputPort         = 'clk_enable';

% Retiming and Pipelining for 100 MHz Timing Closure
cfg.AdaptivePipelining           = true;
cfg.DistributedPipelining        = true;
cfg.RegisterInputs               = true;
cfg.RegisterOutputs              = true;

% Standard Cell Mapping (Generic DFFs/gates, zero FPGA-specific primitives)
cfg.RAMArchitecture              = 'GenericRAM';

f = single(0.0);

fprintf('[1/6] Synthesizing Alamouti 2x2 STBC Encoder (alamouti_encoder_hw)...\n');
try
    codegen -config cfg alamouti_encoder_hw -args {f, f, f, f} -d target_dir
    fprintf('      SUCCESS: Generated Verilog for alamouti_encoder_hw\n');
catch ME
    fprintf('      ERROR in alamouti_encoder_hw: %s\n', ME.message);
end

fprintf('[2/6] Synthesizing Alamouti 2x2 MRC Combiner (alamouti_combiner_hw)...\n');
try
    codegen -config cfg alamouti_combiner_hw -args {f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f} -d target_dir
    fprintf('      SUCCESS: Generated Verilog for alamouti_combiner_hw\n');
catch ME
    fprintf('      ERROR in alamouti_combiner_hw: %s\n', ME.message);
end

fprintf('[3/6] Synthesizing Pipelined Water-Filling Engine (water_filling_hw)...\n');
try
    codegen -config cfg water_filling_hw -args {f, f, single(1.0), single(0.1)} -d target_dir
    fprintf('      SUCCESS: Generated Verilog for water_filling_hw\n');
catch ME
    fprintf('      ERROR in water_filling_hw: %s\n', ME.message);
end

fprintf('[4/6] Synthesizing Dynamic Rank Adaptation Controller (adaptive_controller_hw)...\n');
try
    codegen -config cfg adaptive_controller_hw -args {single(1.0), single(1.0), single(10.0), single(4.5), single(6.31)} -d target_dir
    fprintf('      SUCCESS: Generated Verilog for adaptive_controller_hw\n');
catch ME
    fprintf('      ERROR in adaptive_controller_hw: %s\n', ME.message);
end

fprintf('[5/6] Synthesizing Hard Decision QAM Slicer (qam_slicer_hw)...\n');
try
    codegen -config cfg qam_slicer_hw -args {f, f, single(4.0)} -d target_dir
    fprintf('      SUCCESS: Generated Verilog for qam_slicer_hw\n');
catch ME
    fprintf('      ERROR in qam_slicer_hw: %s\n', ME.message);
end

fprintf('[6/6] Synthesizing Ordered MMSE-SIC Detector (mmse_sic_hw)...\n');
try
    codegen -config cfg mmse_sic_hw -args {f, f, f, f, f, f, f, f, f, f, f, f, single(0.01), single(4.0)} -d target_dir
    fprintf('      SUCCESS: Generated Verilog for mmse_sic_hw\n');
catch ME
    fprintf('      ERROR in mmse_sic_hw: %s\n', ME.message);
end

fprintf('\n======================================================================\n');
fprintf(' HDL CODER GENERATION COMPLETE: Target Directory -> hdl_asic/build_rtl/\n');
fprintf('======================================================================\n');
