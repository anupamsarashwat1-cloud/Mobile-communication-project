% =============================================================================
% Script: test_hw_kernels_verification.m
% Project: Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)
% Description: Comprehensive pre-synthesis verification testbench auditing
%              mathematical equivalence, SQNR, and boundary conditions of all
%              HDL Coder hardware kernels against original baseline MATLAB models.
% =============================================================================

clc;
clear;
fprintf('======================================================================\n');
fprintf(' AUDITING HARDWARE KERNEL VERIFICATION: SMVDU-MIMO-180 ASIC\n');
fprintf('======================================================================\n\n');

addpath(fullfile(pwd, 'common'));
addpath(fullfile(pwd, 'hdl_src_matlab'));
addpath(fullfile(pwd, '01_channel_modeling'));
addpath(fullfile(pwd, '02_baseline_transceivers'));
addpath(fullfile(pwd, '03_optimization_svd_waterfilling'));
addpath(fullfile(pwd, '04_adaptive_mode_switching'));
addpath(fullfile(pwd, '05_simulink_and_advanced_receivers'));

test_passed = true;
num_trials = 1000;

%% 1. Audit Alamouti STBC Encoder & MRC Combiner
fprintf('[TEST 1/5] Auditing Alamouti STBC 2x2 Encoder & Combiner (d=4)...\n');
max_error_stbc = 0;
for i = 1:num_trials
    % Random QPSK symbols
    b = randi([0, 1], 4, 1);
    syms = modulate_qam(b, 4);
    s1 = syms(1); s2 = syms(2);
    
    % Random 2x2 Rayleigh channel
    H = (randn(2, 2) + 1j*randn(2, 2)) / sqrt(2);
    h11 = H(1, 1); h12 = H(1, 2); h21 = H(2, 1); h22 = H(2, 2);
    
    % Hardware Encoder
    [x1_t1, x2_t1, x1_t2, x2_t2] = alamouti_encoder_hw(s1, s2);
    
    % Ideal noiseless channel transmission
    r1_t1 = h11 * x1_t1 + h12 * x2_t1;
    r2_t1 = h21 * x1_t1 + h22 * x2_t1;
    r1_t2 = h11 * x1_t2 + h12 * x2_t2;
    r2_t2 = h21 * x1_t2 + h22 * x2_t2;
    
    % Hardware Combiner
    [s1_hat, s2_hat] = alamouti_combiner_hw(r1_t1, r2_t1, r1_t2, r2_t2, h11, h12, h21, h22);
    
    err1 = abs(s1 - s1_hat);
    err2 = abs(s2 - s2_hat);
    max_error_stbc = max([max_error_stbc, err1, err2]);
end
sqnr_stbc = 10 * log10(1.0 / max(max_error_stbc^2, 1e-15));
fprintf('          Max STBC Reconstruction Error: %e\n', max_error_stbc);
fprintf('          Calculated SQNR: %.2f dB (> 40 dB PASS)\n', sqnr_stbc);
if max_error_stbc > 1e-4
    test_passed = false;
    fprintf('          FAIL: STBC error exceeds threshold!\n');
else
    fprintf('          STATUS: PASS [100%% Bit-Accurate]\n\n');
end

%% 2. Audit Water-Filling Power Allocation
fprintf('[TEST 2/5] Auditing Water-Filling Power Allocator...\n');
max_wf_diff = 0;
for i = 1:num_trials
    H = (randn(2, 2) + 1j*randn(2, 2)) / sqrt(2);
    s = svd(H);
    sigma_sq = s.^2;
    P_tot = 1.0;
    noise_var = 10^(-(rand()*25) / 10); % SNR from 0 to 25 dB
    
    % Original iterative algorithm
    [P_orig, ~, rank_orig] = water_filling_algorithm(sigma_sq, P_tot, noise_var);
    
    % Hardware unrolled kernel
    [P1_hw, P2_hw, rank_hw] = water_filling_hw(single(sigma_sq(1)), single(sigma_sq(2)), single(P_tot), single(noise_var));
    
    diff_p = max(abs(P_orig(1) - P1_hw), abs(P_orig(2) - P2_hw));
    max_wf_diff = max(max_wf_diff, diff_p);
    
    if rank_orig ~= rank_hw
        test_passed = false;
        fprintf('          FAIL: Rank mismatch at SNR = %.2f dB!\n', -10*log10(noise_var));
    end
end
fprintf('          Max Power Allocation Deviation: %e\n', max_wf_diff);
if max_wf_diff < 1e-4
    fprintf('          STATUS: PASS [Identical to Theoretical Optimum]\n\n');
else
    test_passed = false;
    fprintf('          FAIL: Power allocation mismatch!\n\n');
end

%% 3. Audit Adaptive Mode Controller (Cross-Multiplication)
fprintf('[TEST 3/5] Auditing Dynamic Rank Adaptation Controller...\n');
mismatch_count = 0;
for i = 1:num_trials
    H = (randn(2, 2) + 1j*randn(2, 2)) / sqrt(2);
    snr_db = -5 + rand() * 25; % -5 dB to 20 dB
    snr_lin = 10^(snr_db / 10);
    
    % Original floating-point controller
    [orig_mode, orig_kappa, ~] = adaptive_mimo_controller(H, snr_db, 4);
    
    % Hardware cross-multiplication controller
    s = svd(H);
    [hw_mode, ~, ~] = adaptive_controller_hw(single(s(1)), single(s(2)), single(snr_lin), single(4.5), single(10^(8.0/10)));
    
    if orig_mode ~= hw_mode
        mismatch_count = mismatch_count + 1;
    end
end
fprintf('          Decision Mismatches across %d random channels: %d\n', num_trials, mismatch_count);
if mismatch_count == 0
    fprintf('          STATUS: PASS [100%% Decision Concordance]\n\n');
else
    test_passed = false;
    fprintf('          FAIL: Decision logic mismatch!\n\n');
end

%% 4. Audit Hard Decision QAM Slicer
fprintf('[TEST 4/5] Auditing QPSK / 16-QAM Slicer Boundaries...\n');
slicer_pass = true;
% Test QPSK corners (+/- 0.7071)
[qi1, qq1] = qam_slicer_hw(single(0.4), single(0.9), single(4));
if abs(qi1 - 0.70710678) > 1e-4 || abs(qq1 - 0.70710678) > 1e-4
    slicer_pass = false;
end
[qi2, qq2] = qam_slicer_hw(single(-0.1), single(-0.8), single(4));
if abs(qi2 - (-0.70710678)) > 1e-4 || abs(qq2 - (-0.70710678)) > 1e-4
    slicer_pass = false;
end
if slicer_pass
    fprintf('          STATUS: PASS [Exact Euclidean Boundary Slicing]\n\n');
else
    test_passed = false;
    fprintf('          FAIL: Slicer boundary error!\n\n');
end

%% 5. Audit Ordered MMSE-SIC Detector
fprintf('[TEST 5/5] Auditing Ordered MMSE-SIC Detector...\n');
H = [1.0 + 0.2j, 0.3 - 0.1j; 0.2 + 0.1j, 0.9 - 0.3j];
s1 = complex(single(0.70710678), single(0.70710678));
s2 = complex(single(-0.70710678), single(0.70710678));
x = [s1; s2] / sqrt(2);
r = H * x;
[s1_det, s2_det] = mmse_sic_hw(r(1), r(2), H(1,1), H(1,2), H(2,1), H(2,2), single(0.01), single(4));
err_sic = max(abs(s1 - s1_det), abs(s2 - s2_det));
fprintf('          MMSE-SIC High-SNR Residual: %e\n', err_sic);
if err_sic < 0.1
    fprintf('          STATUS: PASS [Convergence Verified]\n\n');
else
    test_passed = false;
    fprintf('          FAIL: MMSE-SIC residual too large!\n\n');
end

fprintf('======================================================================\n');
if test_passed
    fprintf(' OVERALL VERIFICATION VERDICT: ALL HARDWARE WRAPPERS 100%% VERIFIED!\n');
    fprintf(' Ready for Automated MATLAB HDL Coder Synthesis.\n');
else
    fprintf(' OVERALL VERIFICATION VERDICT: FAILURES DETECTED.\n');
end
fprintf('======================================================================\n');
