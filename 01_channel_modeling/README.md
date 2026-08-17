# Stage 1: Spatially Correlated Rayleigh MIMO Channel Modeling

## 1. Overview & Objectives
In real-world 5G deployments (especially at sub-6 GHz and mmWave frequencies), antenna elements at the base station and user equipment (UE) experience **spatial correlation** due to limited angular spread, tight antenna spacing (< λ/2), and insufficient scattering.

This stage models a fixed Nt x Nr MIMO Rayleigh flat-fading channel under arbitrary spatial correlation levels and analyzes its mathematical conditioning.

---

## 2. Mathematical Formulation

### 2.1 The Kronecker Correlation Model
The full MIMO channel matrix H (size Nr x Nt) with transmit correlation matrix R_Tx and receive correlation matrix R_Rx is expressed using the Kronecker product model:

$$\mathbf{H} = \mathbf{R}_{Rx}^{1/2} \mathbf{H}_{iid} \left(\mathbf{R}_{Tx}^{1/2}\right)^T$$

Where:
* **H_iid** is the uncorrelated independent identically distributed Rayleigh fading matrix with complex Gaussian entries:

$$h_{ij} = \frac{1}{\sqrt{2}}(u + jv), \quad u, v \sim \mathcal{N}(0, 1)$$

* **R_Tx** and **R_Rx** are the spatial correlation matrices modeled using the exponential correlation model:

$$[\mathbf{R}_{Tx}]_{i,j} = \rho_{tx}^{|i - j|}, \quad [\mathbf{R}_{Rx}]_{i,j} = \rho_{rx}^{|i - j|}$$

where ρ in [0, 1) is the spatial correlation coefficient.

### 2.2 Singular Value Decomposition & Condition Number
Applying Singular Value Decomposition (SVD):

$$\mathbf{H} = \mathbf{U} \mathbf{\Sigma} \mathbf{V}^H$$

where Σ = diag(σ_1, σ_2, ..., σ_min(Nt, Nr)) contains ordered singular values σ_1 ≥ σ_2 ≥ ... ≥ 0.

The **Condition Number** of the channel matrix is defined as:

$$\kappa(\mathbf{H}) = \frac{\sigma_{max}(\mathbf{H})}{\sigma_{min}(\mathbf{H})} = \frac{\sigma_1}{\sigma_2}$$

* **Well-Conditioned Channel (κ ≈ 1):** Spatial sub-channels are orthogonal; ideal for full rank spatial multiplexing.
* **Ill-Conditioned Channel (κ >> 1):** Spatial sub-channels are collinear; linear spatial multiplexing (ZF) causes catastrophic noise amplification.

---

## 3. Files in this Folder

| File | Description |
|---|---|
| [`generate_correlated_channel.m`](generate_correlated_channel.m) | Vectorized function generating Nt x Nr x K correlated Rayleigh channel realizations. |
| [`test_channel_statistics.m`](test_channel_statistics.m) | Statistical validation script analyzing singular value PDFs and condition number growth across correlation sweeps. |
| [`figures/`](figures/) | Contains exported analytical figures and distribution plots. |

---

## 4. Key Results & Observations

```mermaid
graph LR
    A["Spatial Correlation rho Increases"] --> B["Singular Value Disparity: sigma_1 >> sigma_2"]
    B --> C["Condition Number kappa(H) Explodes"]
    C --> D["Rank Deficient Channel: Spatial Multiplexing Fails"]
    C --> E["Requires Adaptive Optimization / Water-Filling"]
```

### 4.1 Singular Value Distribution
![Singular Value Distribution](figures/singular_value_pdf.png)

### 4.2 Channel Condition Number Growth
![Condition Number vs Correlation](figures/condition_number_vs_correlation.png)

1. **Singular Value Degradation:** As ρ → 1, the second singular value σ_2 → 0, concentrating all channel energy into the dominant spatial mode σ_1.
2. **Exponential Condition Number Growth:** At ρ = 0, mean condition number is ≈ 3.5. At ρ = 0.9, mean condition number exceeds 25, confirming the necessity of adaptive rank and water-filling power allocation.
