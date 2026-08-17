# 5G MIMO Multiplexing Optimization Project — Implementation Plan

> **Academic Course**: ECL DC 401 — Mobile Communication  
> **Topic**: MIMO Diversity vs. Spatial Multiplexing Optimization in 5G Wireless Links  
> **Key Directive (Prof. Feedback)**: *"Multiplexing efficiencies — optimize for fixed no. of MIMO"*  
> **Platform**: MATLAB & Simulink (R2020a - R2026a+) | Native Tool-Free Portability  
> **Repository**: [https://github.com/anupamsarashwat1-cloud/Mobile-communication-project](https://github.com/anupamsarashwat1-cloud/Mobile-communication-project)

---

## 1. Project Objectives & Mathematical Framework

The core scientific goal is to resolve the fundamental trade-off between **Spatial Diversity** (reliability/robustness, maximizing diversity order d) and **Spatial Multiplexing** (throughput/spectral efficiency, maximizing multiplexing gain r) for a **fixed 2x2 MIMO antenna configuration**.

```math
\mathbf{y} = \mathbf{H}\mathbf{x} + \mathbf{n}, \quad \mathbf{H} \in \mathbb{C}^{2 \times 2}, \quad \mathbf{n} \sim \mathcal{CN}(0, \sigma_n^2 \mathbf{I}_2)
```

### Key Mathematical Pillars:
1. **Spatial Correlation (Kronecker Model)**:

```math
\mathbf{H} = \mathbf{R}_{Rx}^{1/2} \mathbf{H}_{iid} \left(\mathbf{R}_{Tx}^{1/2}\right)^T
```

2. **Channel Condition Number (κ(H))**:

```math
\kappa(\mathbf{H}) = \frac{\sigma_{max}(\mathbf{H})}{\sigma_{min}(\mathbf{H})}
```

3. **Singular Value Decomposition & Optimal Water-Filling**:

```math
\mathbf{H} = \mathbf{U} \mathbf{\Sigma} \mathbf{V}^H
```

```math
P_i^{\ast} = \max \left( 0, \; \mu - \frac{\sigma_n^2}{\sigma_i^2} \right), \quad \sum_{i=1}^{r} P_i^{\ast} = P_{total}
```

4. **Adaptive Rank Switching**:

```math
\text{Mode} = \begin{cases} \text{Rank-2 (Spatial Multiplexing)}, & \text{if } \gamma \ge 8.0\text{ dB} \text{ and } \kappa(\mathbf{H}) \le 4.5 \\ \text{Rank-1 (Alamouti STBC Diversity)}, & \text{otherwise} \end{cases}
```

5. **Ordered Non-Linear Successive Interference Cancellation (MMSE-SIC / V-BLAST)**:
   Cancels the strongest stream post-MMSE filtering to achieve full second-order diversity on the remaining stream.

6. **Zheng-Tse Diversity-Multiplexing Trade-off (DMT) Bound**:

```math
d^{\ast}(r) = (N_t - r)(N_r - r) = (2-r)^2
```

---

## 2. Six-Stage Architecture & Deliverables

```mermaid
flowchart LR
    S1["Stage 1: Channel Modeling\n(Kronecker & Kappa)"] --> S2["Stage 2: Baselines\n(Alamouti vs ZF/MMSE)"]
    S2 --> S3["Stage 3: Water-Filling\n(SVD Optimization)"]
    S3 --> S4["Stage 4: Adaptive Engine\n(Goodput Envelope)"]
    S4 --> S5["Stage 5: Receivers\n(MMSE-SIC & Simulink)"]
    S5 --> S6["Stage 6: Master Suite\n(DMT & Benchmarks)"]
```

| Stage | Script / Model | Description | Output Figures |
|---|---|---|---|
| **Stage 1** | `01_channel_modeling/test_channel_statistics.m` | Correlated Rayleigh MIMO channel generation, SVD decomposition, and condition number κ(H) distribution. | `singular_value_pdf.png`<br>`condition_number_vs_correlation.png` |
| **Stage 2** | `02_baseline_transceivers/run_baseline_comparison.m` | Uncoded 2x2 Spatial Multiplexing (ZF & MMSE) vs 2x2 Alamouti STBC Diversity (d=4). | `alamouti_vs_sm_ber.png`<br>`zf_noise_amplification_analysis.png` |
| **Stage 3** | `03_optimization_svd_waterfilling/run_capacity_optimization.m` | SVD eigen-beamforming and exact iterative water-filling power allocation. | `capacity_wf_vs_equal_power.png`<br>`capacity_gain_vs_correlation.png` |
| **Stage 4** | `04_adaptive_mode_switching/run_adaptive_switching_simulation.m` | Dynamic rank-adaptation controller based on instantaneous SNR and condition number κ(H). | `effective_goodput_envelope.png`<br>`mode_switching_decision_boundary.png` |
| **Stage 5** | `05_simulink_and_advanced_receivers/run_sic_simulation.m` | Non-linear Ordered MMSE-SIC (V-BLAST) receiver and Simulink model synthesis. | `sic_vs_linear_receivers_ber.png`<br>`simulink_model_overview.png` |
| **Stage 6** | `06_master_runner_and_benchmarks/main_benchmark_suite.m` | Unified master simulation runner, Zheng-Tse DMT theoretical bound, and 4-panel dashboard. | `master_comprehensive_summary.png`<br>`dmt_diversity_multiplexing_curve.png` |

---

## 3. Terminal & GUI Execution Matrix

All scripts can be executed through:
1. **Interactive MATLAB App**: `gui_dashboard` (one-click buttons with embedded plotting).
2. **Terminal PowerShell Batch**: `matlab -batch "run('06_master_runner_and_benchmarks/main_benchmark_suite.m');"`
3. **MATLAB Online**: Run scripts directly in browser after cloning.
