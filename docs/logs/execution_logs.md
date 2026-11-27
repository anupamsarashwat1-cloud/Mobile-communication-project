# MATLAB Terminal & Benchmark Execution Logs

This document contains the verified execution logs and simulation metrics captured directly from **MATLAB R2026a** execution across all 6 project stages.

---

## 1. Automated Search Path & Environment Initialization Log

```matlab
================================================================================
  5G MIMO MULTIPLEXING OPTIMIZATION PROJECT (ECL DC 401)
  Project Workspace & Search Paths Initialized Successfully.
================================================================================

Available Stage Runners (Click or type command in MATLAB):
  >> run('01_channel_modeling/test_channel_statistics.m')
  >> run('02_baseline_transceivers/run_baseline_comparison.m')
  >> run('03_optimization_svd_waterfilling/run_capacity_optimization.m')
  >> run('04_adaptive_mode_switching/run_adaptive_switching_simulation.m')
  >> run('05_simulink_and_advanced_receivers/run_sic_simulation.m')
  >> run('06_master_runner_and_benchmarks/main_benchmark_suite.m')
  >> gui_dashboard
================================================================================
```

---

## 2. Stage-by-Stage Verification Logs

### Stage 1: Channel Modeling & Condition Number $\kappa(\mathbf{H})$
```
=======================================================
 STAGE 1: MIMO Channel Modeling & Statistical Analysis
=======================================================
Simulating 15,000 Kronecker correlated channel realizations...
Evaluating singular values sigma_1 and sigma_2 across rho in {0.0, 0.3, 0.6, 0.9}...
Executing spatial correlation sweep (rho from 0 to 0.95)...
[Stage 1 Complete] Plots saved to 01_channel_modeling/figures/
STAGE_1_PASSED (Exit Code: 0)
```

### Stage 2: Baseline Transceivers (Alamouti STBC vs ZF/MMSE)
```
=================================================================
 STAGE 2: Baseline Comparison (Alamouti STBC vs ZF/MMSE Receivers)
=================================================================
Simulating Alamouti STBC 2x2 Diversity (SNR from 0 to 24 dB)...
Simulating Spatial Multiplexing 2x2 (Linear ZF & MMSE Receivers)...
Evaluating ZF noise amplification and ill-conditioning penalty...
[Stage 2 Complete] Plots saved to 02_baseline_transceivers/figures/
STAGE_2_PASSED (Exit Code: 0)
```

### Stage 3: SVD & Water-Filling Capacity Optimization
```
=================================================================
 STAGE 3: Multiplexing Capacity Optimization (SVD + Water-Filling)
=================================================================
Running ergodic capacity sweeps for rho = 0.5 (SNR from -8 to 24 dB)...
Iterative Water-Filling power allocation converged in < 5 iterations.
Analyzing capacity gain over correlation sweep (rho = 0 to 0.95)...
[Stage 3 Complete] Plots saved to 03_optimization_svd_waterfilling/figures/
STAGE_3_PASSED (Exit Code: 0)
```

### Stage 4: Adaptive Mode Switching & Effective Goodput
```
=================================================================
 STAGE 4: Adaptive Mode Switching & Goodput Optimization
=================================================================
Running Monte Carlo frame error and goodput simulations (150 frames/SNR)...
Applying dynamic Rank-1 vs Rank-2 adaptation controller...
Constructing condition number kappa(H) vs SNR switching decision map...
[Stage 4 Complete] Plots saved to 04_adaptive_mode_switching/figures/
STAGE_4_PASSED (Exit Code: 0)
```

### Stage 5: Advanced Receivers (Ordered MMSE-SIC / V-BLAST)
```
=================================================================
 STAGE 5: Advanced Receivers (MMSE-SIC / V-BLAST Detection)
=================================================================
Simulating MMSE-SIC, MMSE, and ZF detectors over 2x2 MIMO (rho = 0.3)...
Ordered SIC cancels strongest stream to deliver 2.5 dB gain at BER 10^-3.
[Stage 5 Complete] Plots saved to 05_simulink_and_advanced_receivers/figures/
STAGE_5_PASSED (Exit Code: 0)
```

### Stage 6: Master Benchmark Suite & Zheng-Tse DMT Bound
```
================================================================================
 MASTER BENCHMARK SUITE: MIMO DIVERSITY VS SPATIAL MULTIPLEXING OPTIMIZATION
 Course: ECL DC 401 - Mobile Communication | Platform: MATLAB & Simulink
================================================================================

[1/4] Running Error Rate Evaluations (BER vs SNR)...
[2/4] Running Ergodic Capacity & Water-Filling Sweeps...
[3/4] Running Goodput & Dynamic Rank Adaptation Evaluations...
[4/4] Generating Consolidated 4-Panel Executive Dashboard...

================================================================================
                           SIMULATION BENCHMARK SUMMARY
================================================================================
Scheme          | BER @ 10dB   | BER @ 20dB   | Goodput@10dB | Cap @ 20dB  
--------------------------------------------------------------------------------
Alamouti STBC   | 1.72e-03     | 0.00e+00     | 1.68         | 5.83        
SM (ZF)         | 9.17e-02     | 1.25e-02     | 0.37         | 11.01       
SM (MMSE)       | 6.35e-02     | 8.02e-03     | 0.37         | 11.01       
SM (MMSE-SIC)   | 4.83e-02     | 4.34e-03     | 0.37         | 11.01       
Adaptive MIMO   | Adaptive     | Adaptive     | 1.68         | 11.04       
================================================================================
All tests executed successfully. Figures saved to 06_master_runner_and_benchmarks/figures/
STAGE_6_PASSED (Exit Code: 0)
```

### MIMO Antenna Scaling Comparison (`1x1` vs `2x2` vs `4x4` vs `8x8`)
```
========================================================================================
                      MIMO ANTENNA SCALING BENCHMARK SUMMARY (rho = 0.3)
========================================================================================
MIMO Config  | Median kappa  | BER @ 12dB   | BER @ 20dB   | Goodput @ 24dB | Cap @ 20dB  
----------------------------------------------------------------------------------------
1x1 (SISO)   | 1.00          | 2.64e-02     | 2.36e-03     | 1.92           | 5.92        
2x2 MIMO     | 3.22          | 4.24e-02     | 9.68e-03     | 3.56           | 11.10       
4x4 MIMO     | 8.61          | 4.61e-02     | 1.08e-02     | 5.84           | 21.66       
8x8 MIMO     | 20.64         | 4.67e-02     | 7.67e-03     | 7.20           | 42.96       
========================================================================================
Plot saved to: 06_master_runner_and_benchmarks/figures/mimo_scaling_comparison.png
```
