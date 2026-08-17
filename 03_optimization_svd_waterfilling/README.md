# Stage 3: Multiplexing Optimization via SVD and Water-Filling

## 1. Overview & Motivation
For a fixed antenna count (e.g. 2x2 MIMO), unprecoded equal-power spatial multiplexing wastes transmit power on weak spatial eigenmodes, particularly in the presence of spatial correlation or low SNR. 

This stage implements the theoretically optimal spatial multiplexing transceiver by combining **Singular Value Decomposition (SVD) channel diagonalisation** with the **Water-Filling power allocation algorithm**.

---

## 2. Mathematical Formulation

### 2.1 SVD Channel Decoupling
Given channel realization H (size Nr x Nt), we perform SVD:

$$\mathbf{H} = \mathbf{U} \mathbf{\Sigma} \mathbf{V}^H$$

* **Transmitter Precoding:** The symbol vector s = [s_1, ..., s_r]^T is precoded by right-singular matrix V:

$$\mathbf{x} = \mathbf{V} \mathbf{P}^{1/2} \mathbf{s}$$

where P = diag(P_1, ..., P_r) is the power allocation matrix.

* **Receiver Combining:** The received signal y = Hx + n is combined by left-singular matrix U^H:

$$\mathbf{\tilde{y}} = \mathbf{U}^H \mathbf{y} = \mathbf{\Sigma} \mathbf{P}^{1/2} \mathbf{s} + \mathbf{\tilde{n}}$$

Since U is unitary, the transformed noise remains white Gaussian noise.

This decomposes the coupled Nt x Nr MIMO channel into r = min(Nt, Nr) completely independent parallel SISO sub-channels:

$$\tilde{y}_i = \sigma_i \sqrt{P_i} s_i + \tilde{n}_i, \quad i = 1, \dots, r$$

### 2.2 Water-Filling Optimization (Lagrangian Derivation)
To maximize sum spectral efficiency under total transmit power constraint P_total:

$$\max_{\{P_i\}} \sum_{i=1}^{r} \log_2 \left( 1 + \frac{P_i \sigma_i^2}{\sigma_n^2} \right) \quad \text{subject to } \sum_{i=1}^{r} P_i = P_{total}, \; P_i \ge 0$$

Formulating the Lagrangian with multiplier λ:

$$\mathcal{L}(P_1, \dots, P_r, \lambda) = \sum_{i=1}^{r} \ln \left( 1 + \frac{P_i \sigma_i^2}{\sigma_n^2} \right) - \lambda \left( \sum_{i=1}^{r} P_i - P_{total} \right)$$

Taking the partial derivative with respect to P_i yields the optimal water-filling solution:

$$P_i^* = \max \left( 0, \; \mu - \frac{\sigma_n^2}{\sigma_i^2} \right)$$

where μ = 1/λ is the **water level** determined by the constraint sum(P_i*) = P_total.

---

## 3. Files in this Folder

| File | Description |
|---|---|
| [`water_filling_algorithm.m`](water_filling_algorithm.m) | Exact iterative water-filling optimizer solving for water level μ and optimal power vector P*. |
| [`svd_precoder_combiner.m`](svd_precoder_combiner.m) | Channel SVD decomposition, eigen-precoder and combiner synthesis. |
| [`run_capacity_optimization.m`](run_capacity_optimization.m) | Ergodic capacity simulation comparing SVD-WF vs SVD Equal-Power vs Dominant Eigenmode Beamforming across SNR and correlation sweeps. |
| [`figures/`](figures/) | Contains exported capacity curves and percentage gain analysis plots. |

---

## 4. Key Findings & Performance Gains

```mermaid
graph LR
    A["Low SNR Regime"] --> B["Water-Filling Pours All Power to sigma_1"]
    B --> C["Acts as Optimal Beamformer / Diversity"]
    D["High SNR Regime"] --> E["Water Level Exceeds 1/SNR for All Modes"]
    E --> F["Pours Equal Power across all streams: Full Multiplexing"]
```

### 4.1 Ergodic Spectral Efficiency vs SNR
![Ergodic Capacity: Water-Filling vs Equal Power](figures/capacity_wf_vs_equal_power.png)

### 4.2 Percentage Gain under High Spatial Correlation
![Water-Filling Percentage Gain](figures/capacity_gain_vs_correlation.png)

1. **Low SNR Advantage:** At SNR < 0 dB, Water-filling allocates 100% of power to the dominant eigenmode (σ_1), automatically avoiding wasting energy on noisy sub-channels.
2. **Correlation Resilience:** When spatial correlation ρ = 0.9, Water-Filling provides up to **48.5% capacity gains** over unoptimized equal-power transmission.
