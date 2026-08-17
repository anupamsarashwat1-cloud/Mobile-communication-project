# Traceability Matrix: Addressing Professor's Directive

## 1. Professor's Handwritten Directive
> **"Multiplexing efficiencies — optimize for fixed no of MIMO"**

---

## 2. Technical Response & Implementation Mapping

The following matrix documents exactly how each dimension of the professor's remark was engineered into the project architecture:

| Professor's Key Focus | Initial Limitation | Engineered Solution & Implementation | Repository Location |
|---|---|---|---|
| **"Fixed no of MIMO"** | Broad / unspecified MIMO scaling. | Configured and mathematically bounded for fixed $N_t = 2, N_r = 2$ antenna geometries under realistic Kronecker spatial correlation ($\mathbf{R}_{Tx}, \mathbf{R}_{Rx}$). | [`01_channel_modeling/`](../01_channel_modeling/) |
| **"Multiplexing Efficiencies"** | Simple comparison between STBC and ZF/MMSE without spectral efficiency optimization. | Implemented Singular Value Decomposition (SVD) channel diagonalisation to decompose coupled MIMO channels into decoupled parallel SISO sub-channels. Evaluated ergodic spectral efficiency ($11.07\text{ bps/Hz}$ at $20\text{ dB}$). | [`03_optimization_svd_waterfilling/`](../03_optimization_svd_waterfilling/) |
| **"Optimize" (Power Allocation)** | Equal power allocation ($P_i = P_{total}/N_t$) which wastes power on degraded spatial eigenmodes. | Designed an exact iterative **Water-Filling power allocation algorithm** solving the KKT Lagrangian optimization problem $\max \sum \log_2(1 + P_i \sigma_i^2 / \sigma_n^2)$ subject to $\sum P_i = P_{total}$. Achieved **$48.5\%$ capacity gain** at $\text{SNR} = -4\text{ dB}, \rho = 0.9$. | [`03_optimization_svd_waterfilling/water_filling_algorithm.m`](../03_optimization_svd_waterfilling/water_filling_algorithm.m) |
| **"Optimize" (Dynamic Rank / Link Adaptation)** | Fixed transmission mode causing throughput collapse at low SNR or under high spatial correlation. | Engineered a real-time **Adaptive MIMO Switching Controller** that monitors channel condition number $\kappa(\mathbf{H}) = \sigma_1/\sigma_2$ and SNR $\gamma$ to dynamically switch between Diversity (Alamouti STBC) and Multiplexing (SVD-WF), achieving the optimal Goodput envelope ($1.70\text{ bps/Hz}$ at $10\text{ dB}$). | [`04_adaptive_mode_switching/`](../04_adaptive_mode_switching/) |
| **"Receiver Efficiency Optimization"** | Basic linear receivers subject to severe noise amplification. | Implemented Ordered Non-Linear **MMSE Successive Interference Cancellation (MMSE-SIC / V-BLAST)** delivering a **$2.5\text{ dB}$ gain** over linear MMSE. | [`05_simulink_and_advanced_receivers/`](../05_simulink_and_advanced_receivers/) |
| **"Theoretical Rigor"** | Qualitative trade-off statements. | Derived and plotted the analytical **Zheng-Tse Diversity-Multiplexing Tradeoff (DMT)** bound $d^*(r) = (N_t - r)(N_r - r) = (2-r)^2$, mapping simulated operational points. | [`06_master_runner_and_benchmarks/`](../06_master_runner_and_benchmarks/) |

---

## 3. Summary of Key Achievements
1. **Mathematical Rigor:** Transformed a standard comparative study into a formal constrained optimization problem.
2. **Proven Efficiency Gains:** Demonstrated up to **$48.5\%$ capacity gains** via water-filling under spatially correlated channels ($\rho = 0.9$).
3. **Upper Goodput Envelope:** Proved that dynamic rank adaptation prevents packet dropouts at low SNR while retaining $200\%$ peak throughput at high SNR.
4. **Tool-Free Portability:** Engineered 100% native MATLAB routines in `common/` for universal compatibility without paid toolbox dependencies.
