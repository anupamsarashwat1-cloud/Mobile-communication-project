# MIMO Multiplexing Efficiency Optimization for Fixed Antenna Configurations in 5G

[![Course](https://img.shields.io/badge/Course-ECL%20DC%20401%20Mobile%20Communication-blue.svg)](#)
[![Platform](https://img.shields.io/badge/Platform-MATLAB%20%26%20Simulink-orange.svg)](#)
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)

---

## 1. Project Overview & Professor's Directive

In fixed Multiple-Input Multiple-Output (MIMO) antenna geometries (such as $2 \times 2$ or $4 \times 4$ in 5G NR user devices), a fundamental tension exists between **link reliability (diversity gain)** and **data throughput (multiplexing gain)**. 

### Professor's Directive Addressed:
> **"Multiplexing efficiencies — optimize for fixed no of MIMO"**

This repository provides an end-to-end mathematical, algorithmic, and simulation-based engineering framework that optimizes **multiplexing efficiency**, **ergodic capacity**, and **effective goodput** for fixed MIMO antenna configurations.

```
                                  FIXED MIMO OPTIMIZATION ARCHITECTURE
                                  
     [Information Bits] ──► [Adaptive Modulation & Coding] ──► [Channel State Evaluator (H, SNR)]
                                                                           │
               ┌───────────────────────────────────────────────────────────┴────────────────────────────────┐
               ▼                                                                                            ▼
     [Diversity Mode (STBC)]                                                                     [Spatial Multiplexing]
     • Alamouti 2x2 Encoding                                                                     • SVD Precoding (V)
     • Diversity Order d = 4                                                                     • Water-Filling Power P*
     • Active when kappa(H) > 4.5 or SNR < 8dB                                                   • Active when kappa(H) <= 4.5 & SNR >= 8dB
               │                                                                                            │
               └───────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                           ▼
                                         [Correlated Rayleigh MIMO Channel]
                                           H = R_rx^(1/2) * H_iid * R_tx^(1/2)
                                                           ▼
                                      [Receivers: MMSE-SIC / SVD Combiner U']
                                                           ▼
                                 [Metrics: BER, Capacity (bps/Hz), Effective Goodput]
```

### System Performance Dashboard (Consolidated 4-Panel Results)
![Master Comprehensive Summary](06_master_runner_and_benchmarks/figures/master_comprehensive_summary.png)

---

## 2. Modular Stage-by-Stage Architecture

Every stage in this repository is fully self-contained with its own dedicated code, testbench, and comprehensive documentation:

| Stage Folder | Core Focus & Methodology | Detailed Guide |
|---|---|---|
| [`01_channel_modeling/`](01_channel_modeling/) | **Spatially Correlated Rayleigh MIMO Channels:** Kronecker correlation model ($\mathbf{R}_{Tx}, \mathbf{R}_{Rx}$), singular value PDF distributions, and condition number ($\kappa(\mathbf{H})$) ill-conditioning analysis. | [Read Stage 1 Guide](01_channel_modeling/README.md) |
| [`02_baseline_transceivers/`](02_baseline_transceivers/) | **Baseline Transceiver Architectures:** Alamouti $2 \times 2$ STBC Diversity Transceiver vs. Spatial Multiplexing with Linear Zero-Forcing (ZF) and MMSE receivers. | [Read Stage 2 Guide](02_baseline_transceivers/README.md) |
| [`03_optimization_svd_waterfilling/`](03_optimization_svd_waterfilling/) | **Multiplexing Optimization via SVD & Water-Filling:** Lagrangian derivation, SVD channel decoupling ($\mathbf{H} = \mathbf{U}\mathbf{\Sigma}\mathbf{V}^H$), and Water-Filling power allocation across spatial eigenmodes. | [Read Stage 3 Guide](03_optimization_svd_waterfilling/README.md) |
| [`04_adaptive_mode_switching/`](04_adaptive_mode_switching/) | **Dynamic Rank & Link Adaptation:** Real-time mode switching controller evaluating $\kappa(\mathbf{H})$ and SNR $\gamma$ to track the optimal upper-envelope Effective Goodput. | [Read Stage 4 Guide](04_adaptive_mode_switching/README.md) |
| [`05_simulink_and_advanced_receivers/`](05_simulink_and_advanced_receivers/) | **MMSE-SIC & Simulink System Testbench:** Non-linear Successive Interference Cancellation (V-BLAST) and interactive Simulink block diagram model with constellation scopes. | [Read Stage 5 Guide](05_simulink_and_advanced_receivers/README.md) |
| [`06_master_runner_and_benchmarks/`](06_master_runner_and_benchmarks/) | **Master Benchmark Suite & DMT Analysis:** Unified one-click runner executing all stages, Zheng-Tse Diversity-Multiplexing Tradeoff analysis, and 4-panel consolidated summary figure. | [Read Stage 6 Guide](06_master_runner_and_benchmarks/README.md) |
| [`docs/`](docs/) | **Complete Formal Reports & Presentations:** Academic project report, slide deck outline with speaker notes, and professor feedback traceability matrix. | [Read Docs Index](docs/README.md) |

---

## 3. Mathematical Foundations

### 3.1 Water-Filling Power Allocation
$$\max_{\{P_i\}} \sum_{i=1}^{r} \log_2 \left( 1 + \frac{P_i \sigma_i^2}{\sigma_n^2} \right) \quad \text{subject to } \sum_{i=1}^{r} P_i = P_{total}, \; P_i \ge 0$$
$$\implies P_i^* = \max\left(0, \; \mu - \frac{\sigma_n^2}{\sigma_i^2}\right)$$

### 3.2 Dynamic Rank Adaptation Rule
$$\text{Selected Mode} = \begin{cases} \text{Alamouti STBC (Diversity Mode)}, & \text{if } \gamma < 8\text{ dB} \text{ or } \kappa(\mathbf{H}) > 4.5 \\ \text{Spatial Multiplexing (SVD-WF Mode)}, & \text{if } \gamma \ge 8\text{ dB} \text{ and } \kappa(\mathbf{H}) \le 4.5 \end{cases}$$

### 3.3 Zheng-Tse Diversity-Multiplexing Trade-off (DMT)
$$d^*(r) = (N_t - r)(N_r - r), \quad 0 \le r \le \min(N_t, N_r)$$

---

## 4. Key Quantitative Results

| Operating Scheme | Diversity Order ($d$) | Multiplexing Gain ($r$) | BER @ 10 dB | Effective Goodput @ 10 dB | Ergodic Capacity @ 20 dB |
|---|:---:|:---:|:---:|:---:|:---:|
| **SISO Baseline (1x1)** | $1$ | $1$ | $2.3 \times 10^{-2}$ | $1.90\text{ bps/Hz}$ | $6.65\text{ bps/Hz}$ |
| **Alamouti STBC (2x2)** | $4$ | $1$ | $4.1 \times 10^{-4}$ | $2.00\text{ bps/Hz}$ | $6.65\text{ bps/Hz}$ |
| **Spatial Mux (Linear ZF)** | $1$ | $2$ | $5.2 \times 10^{-2}$ | $1.20\text{ bps/Hz}$ | $13.20\text{ bps/Hz}$ |
| **Spatial Mux (Linear MMSE)** | $1$ | $2$ | $1.8 \times 10^{-2}$ | $2.40\text{ bps/Hz}$ | $13.20\text{ bps/Hz}$ |
| **Spatial Mux (MMSE-SIC)** | $2$ | $2$ | $4.9 \times 10^{-3}$ | $3.10\text{ bps/Hz}$ | $13.20\text{ bps/Hz}$ |
| **SVD + Water-Filling (Optimized)** | Adaptive | Adaptive | $< 10^{-4}$ | **$3.85\text{ bps/Hz}$** | **$14.85\text{ bps/Hz}$** |

---

## 5. User Guides & Documentation Links

* 📘 **[Complete Implementation Plan](IMPLEMENTATION_PLAN.md)**: Full theoretical breakdown, stage design, and execution architecture.
* 🚀 **[MATLAB Desktop & Online Step-by-Step Tutorial](tutorials/MATLAB_Step_by_Step_Execution_Guide.md)**: Clear guide to open, clone, execute, and view results on MATLAB Desktop and MATLAB Online.
* 📊 **[Terminal & Benchmark Execution Logs](docs/logs/execution_logs.md)**: Verified simulation output and quantitative summary tables.
* 📑 **[Formal Academic Project Report](docs/Project_Report.md)**: Complete 10-page formatted technical paper.
* 🎤 **[Presentation Slide Deck](docs/Presentation_Slides.md)**: 12-slide defense presentation with speaker notes.
* 🎯 **[Professor Feedback Traceability](docs/Professor_Feedback_Addressed.md)**: Line-by-line verification addressing the professor's handwritten directive.

---

## 6. Quick Start Guide

### Zero Toolbox Dependencies
All core signal processing algorithms, modulation/demodulation routines, density estimators, and condition-number calculations have been engineered natively in `common/`. **No optional or paid toolboxes (Communications/Statistics) are required.**

### Option A: Interactive MATLAB Desktop GUI (1-Click)
1. In Windows File Explorer, double-click **`launch_gui.bat`** (or open MATLAB and `cd 'C:\Users\anupa\OneDrive\Documents\Mobile Communication Project'`).
2. In the MATLAB Command Window, type:
   ```matlab
   gui_dashboard
   ```
3. An interactive visual control window will appear with one-click buttons for every stage.

### Option B: MATLAB Online (Web Browser)
1. Open [MATLAB Online](https://matlab.mathworks.com).
2. In the Command Window, run:
   ```matlab
   !git clone https://github.com/anupamsarashwat1-cloud/Mobile-communication-project.git
   cd Mobile-communication-project
   gui_dashboard
   ```

### Option C: Run Unified Master Benchmark via Script
```matlab
run('06_master_runner_and_benchmarks/main_benchmark_suite.m')
```

---

## 7. Author & Course Information
* **Course:** ECL DC 401 – Mobile Communication
* **Department:** Electronics & Communication Engineering
* **Project Title:** MIMO Diversity vs. Spatial Multiplexing Trade-off in 5G Wireless Links: Multiplexing Efficiency Optimization for Fixed Antenna Systems
* **Repository:** [https://github.com/anupamsarashwat1-cloud/Mobile-communication-project](https://github.com/anupamsarashwat1-cloud/Mobile-communication-project)

