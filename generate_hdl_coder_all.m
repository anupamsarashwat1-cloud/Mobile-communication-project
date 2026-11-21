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

% 1. Create ASIC-Grade HDL Coder Configuration
cfg = coder.config('hdl');

% Output target and language
cfg.TargetLanguage          = 'Verilog';
cfg.TargetDirectory         = fullfile(pwd, 'hdl_asic', 'build_rtl');
cfg.InlineConfigurations    = true;
cfg.GenerateComments        = true;

% ASIC Clock and Reset Specification
cfg.ResetType               = 'Synchronous';
cfg.ResetAssertedLevel      = 'Active-high';
cfg.ClockInputPort          = 'clk';
cfg.ResetInputPort          = 'rst';
cfg.ClockEnableInputPort    = 'clk_enable';

% Retiming and Pipelining for 100 MHz Timing Closure
cfg.AdaptivePipelining      = true;
cfg.DistributedPipelining   = true;
cfg.RegisterInputs          = true;
cfg.RegisterOutputs         = true;

% Standard Cell Mapping (Zero FPGA-specific primitives)
cfg.RAMArchitecture         = 'Generic';
cfg.MultiplierPartitioning  = 'None';

% Automated Verification Harness
cfg.GenerateHDLTestBench    = true;
cfg.TestBenchNamePostfix    = '_tb';

fprintf('[1/6] Synthesizing Alamouti 2x2 STBC Encoder (alamouti_encoder_hw)...\n');
s1_type = complex(single(0));
s2_type = complex(single(0));
try
    codegen -config cfg alamouti_encoder_hw -args {s1_type, s2_type}
    fprintf('      SUCCESS: Generated Verilog for alamouti_encoder_hw\n');
catch ME
    fprintf('      WARNING: %s\n', ME.message);
end

fprintf('[2/6] Synthesizing Alamouti 2x2 MRC Combiner (alamouti_combiner_hw)...\n');
c_sample = complex(single(0));
try
    codegen -config cfg alamouti_combiner_hw -args {c_sample, c_sample, c_sample, c_sample, c_sample, c_sample, c_sample, c_sample}
    fprintf('      SUCCESS: Generated Verilog for alamouti_combiner_hw\n');
catch ME
    fprintf('      WARNING: %s\n', ME.message);
end

fprintf('[3/6] Synthesizing Pipelined Water-Filling Engine (water_filling_hw)...\n');
sig_sq = single(0);
p_tot  = single(1.0);
n_var  = single(0.1);
try
    codegen -config cfg water_filling_hw -args {sig_sq, sig_sq, p_tot, n_var}
    fprintf('      SUCCESS: Generated Verilog for water_filling_hw\n');
catch ME
    fprintf('      WARNING: %s\n', ME.message);
end

fprintf('[4/6] Synthesizing Dynamic Rank Adaptation Controller (adaptive_controller_hw)...\n');
sig_val  = single(1.0);
snr_lin  = single(10.0);
k_thresh = single(4.5);
s_thresh = single(6.31);
try
    codegen -config cfg adaptive_controller_hw -args {sig_val, sig_val, snr_lin, k_thresh, s_thresh}
    fprintf('      SUCCESS: Generated Verilog for adaptive_controller_hw\n');
catch ME
    fprintf('      WARNING: %s\n', ME.message);
end

fprintf('[5/6] Synthesizing Hard Decision QAM Slicer (qam_slicer_hw)...\n');
s_coord = single(0.5);
m_order = single(4);
try
    codegen -config cfg qam_slicer_hw -args {s_coord, s_coord, m_order}
    fprintf('      SUCCESS: Generated Verilog for qam_slicer_hw\n');
catch ME
    fprintf('      WARNING: %s\n', ME.message);
end

fprintf('[6/6] Synthesizing Ordered MMSE-SIC Detector (mmse_sic_hw)...\n');
try
    codegen -config cfg mmse_sic_hw -args {c_sample, c_sample, c_sample, c_sample, c_sample, c_sample, n_var, m_order}
    fprintf('      SUCCESS: Generated Verilog for mmse_sic_hw\n');
catch ME
    fprintf('      WARNING: %s\n', ME.message);
end

fprintf('\n======================================================================\n');
fprintf(' HDL CODER GENERATION COMPLETE: Target -> hdl_asic/build_rtl/\n');
fprintf('======================================================================\n');
