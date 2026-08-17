# Stage 6: Master Benchmark Suite & Diversity-Multiplexing Tradeoff (DMT)

## 1. Overview
This stage aggregates the complete simulation pipeline into a unified, one-click execution script. It executes Monte Carlo sweeps across all earlier modules, validates numerical convergence, computes quantitative summary tables, and exports publication-quality performance curves.

---

## 2. Theoretical Background: The Zheng-Tse DMT Bound

In fundamental MIMO information theory (Zheng & Tse, IEEE Trans. Inf. Theory, 2003), a fundamental trade-off exists between reliability (diversity gain d) and throughput (multiplexing gain r).

### 2.1 Formal Definitions
* **Spatial Multiplexing Gain (r):** The asymptotic data rate scaling:

$$r = \lim_{\text{SNR} \to \infty} \frac{R(\text{SNR})}{\log_2(\text{SNR})}$$

* **Diversity Gain (d):** The asymptotic error probability decay slope:

$$d = -\lim_{\text{SNR} \to \infty} \frac{\log P_e(\text{SNR})}{\log(\text{SNR})}$$

### 2.2 Optimal Bound Formulation
For a block-fading channel with coherence time T ≥ Nt + Nr - 1, the optimal trade-off curve d*(r) is given by the piecewise linear function connecting points (r, d*(r)) for integer r in [0, min(Nt, Nr)]:

$$d^*(r) = (N_t - r)(N_r - r)$$

#### For Fixed 2x2 MIMO:
* r = 0 ==> d*(0) = (2-0)(2-0) = 4 *(Alamouti STBC Diversity)*
* r = 1 ==> d*(1) = (2-1)(2-1) = 1 *(Rank-1 Beamforming)*
* r = 2 ==> d*(2) = (2-2)(2-2) = 0 *(Full Spatial Multiplexing)*

---

## 3. Comprehensive Simulation Dashboard & Results

### 3.1 Consolidated 4-Panel Executive Summary Figure
![Master Comprehensive Summary](figures/master_comprehensive_summary.png)

### 3.2 Zheng-Tse Diversity-Multiplexing Trade-off (DMT) Bound
![Diversity-Multiplexing Trade-off (DMT) Bound](figures/dmt_diversity_multiplexing_curve.png)

---

## 4. Files in this Folder

| File | Description |
|---|---|
| [`main_benchmark_suite.m`](main_benchmark_suite.m) | Master runner script executing all stages and exporting the 4-panel consolidated summary figure. |
| [`dmt_tradeoff_analyzer.m`](dmt_tradeoff_analyzer.m) | Computes and plots the theoretical Zheng-Tse DMT bound for 2x2 and 4x4 MIMO systems. |
| [`figures/`](figures/) | Contains the consolidated executive summary figure and DMT trade-off plots. |

---

## 5. How to Run the Benchmark Suite

In the MATLAB Command Window, simply run:
```matlab
run('06_master_runner_and_benchmarks/main_benchmark_suite.m')
```
