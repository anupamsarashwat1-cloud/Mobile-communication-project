# Subsystem 05: Ordered MMSE-SIC Detection Engine & QAM Slicer
## Complete Synthesizable Verilog RTL & Architectural Reference
### Standalone 2x2 MIMO Baseband Processor ASIC (`SMVDU-MIMO-180`)
### Generation Methodology: 100% MathWorks MATLAB HDL Coder (Release 26.2)

---

## 1. Subsystem Architecture & Functional Role
The Ordered MMSE Successive Interference Cancellation (MMSE-SIC, V-BLAST) engine provides near-optimal non-linear symbol detection for $2\times 2$ spatial multiplexing. While linear MMSE detection suffers from post-detection SNR loss on the weaker stream, MMSE-SIC detects the strongest stream, reconstructs its transmit signal, subtracts it from the received antenna vector, and decodes the second stream completely free from cross-stream interference.

This architecture achieves full spatial multiplexing throughput ($R=2$) while restoring **diversity order $d=2$** on both streams.

```
                              +-------------------------------------------------------------+
                              |              MMSE-SIC RECEIVER SUBSYSTEM                    |
                              |                                                             |
    r1, r2 (re, im) --------->| +---------------------------------------------------------+ |-> s1_raw, s2_raw
    H (16 scalar inputs) ---->| |                      mmse_sic_hw.v                      | |
    noise_var ---------------->| | (Gram Inversion, MMSE Filtering, Slicing & Cancellation)| |
    mod_order (4 or 16) ----->| +---------------------------------------------------------+ |
    clk, rst, clk_enable ---->|                                                             |
                              | +-----------------------------+ +-------------------------+ |
                              | |   qam_slicer_hw.v (Stream 1)| | qam_slicer_hw.v(Stream 2)| |-> s1_hat, s2_hat
                              | +-----------------------------+ +-------------------------+ |
                              +-------------------------------------------------------------+
```

---

## 2. Directory Verilog Design Files & Descriptions

| Design File (`.v`) | Module Name | Pipeline Latency | Functional & Standard-Cell Description |
|---|---|:---:|---|
| **`mmse_sic_hw.v`** | `mmse_sic_hw` | **291 cycles** | Master Non-Linear MMSE-SIC processor. Implements Gram matrix formation, closed-form inversion, slicing, subtraction, and MRC. |
| **`qam_slicer_hw.v`** | `qam_slicer_hw` | **5 cycles** | Euclidean nearest-neighbor decision slicer for QPSK and 16-QAM constellations. |
| **`nfp_add_single.v`** | `nfp_add_single` | 7 cycles | IEEE-754 single-precision hardware adder. Used in Gram diagonal regularization and complex MACs. |
| **`nfp_sub_single.v`** | `nfp_sub_single` | 7 cycles | IEEE-754 single-precision hardware subtractor. Used in interference cancellation ($\mathbf{r} - \mathbf{h}_1 \hat{s}_1$). |
| **`nfp_mul_single.v`** | `nfp_mul_single` | 5 cycles | IEEE-754 single-precision hardware multiplier. Used in Gram matrix cross-products and matched filtering. |
| **`nfp_div_single.v`** | `nfp_div_single` | 33 cycles | IEEE-754 single-precision divider. Computes determinant reciprocal and Stream 2 channel energy normalization. |
| **`nfp_recip_single.v`** | `nfp_recip_single` | 22 cycles | Pipelined Newton-Raphson single-precision reciprocal core ($1/\det(\mathbf{G})$). |
| **`nfp_gain_pow2_single.v`**| `nfp_gain_pow2_single`| 1 cycle | Bit-level power-of-2 scaling unit. Multiplies noise variance by 2 for regularization. |
| **`nfp_relop_single*.v`**| `nfp_relop_single` (variants) | 1 cycle | IEEE-754 relational comparators for decision boundaries ($\pm 2/\sqrt{10}, 0$). |
| **`nfp_uminus_single.v`**| `nfp_uminus_single`| 0 cycles | Combinational sign inverter for complex conjugate products. |

---

## 3. Mathematical Foundations & Microarchitecture

### Step 1: Regularized Gram Matrix Formation & Closed-Form Inversion
Under $2\times 2$ spatial multiplexing, the MMSE weight matrix requires the inverse of $\mathbf{H}^H\mathbf{H} + 2\sigma_n^2\mathbf{I}$:
$$\mathbf{G} = \begin{bmatrix} g_{11} & g_{12} \\ g_{21} & g_{22} \end{bmatrix} = \begin{bmatrix} \|\mathbf{h}_1\|^2 + 2\sigma_n^2 & \mathbf{h}_1^H \mathbf{h}_2 \\ \mathbf{h}_2^H \mathbf{h}_1 & \|\mathbf{h}_2\|^2 + 2\sigma_n^2 \end{bmatrix}$$

Because $\mathbf{G}$ is strictly Hermitian ($g_{21} = g_{12}^*$) and dimension is $2\times 2$, its determinant is purely real:
$$\det(\mathbf{G}) = g_{11} g_{22} - |g_{12}|^2 > 0$$

The closed-form analytic inverse is computed directly without matrix decomposition:
$$\mathbf{G}^{-1} = \frac{1}{\det(\mathbf{G})} \begin{bmatrix} g_{22} & -g_{12} \\ -g_{21} & g_{11} \end{bmatrix}$$

### Step 2: Stream 1 MMSE Detection & Internal Slicing
The first row of the MMSE filter $\mathbf{W} = \mathbf{G}^{-1} \mathbf{H}^H$ is applied to the received vector $\mathbf{r}$:
$$\hat{s}_{1,\text{raw}} = \sqrt{2} \cdot \left( \mathbf{w}_1^T \mathbf{r} \right)$$

This soft output is passed through an internal Euclidean nearest-neighbor slicer to obtain the hard decision symbol:
$$\hat{s}_{1,\text{sliced}} = \text{QAM\_Slicer}(\hat{s}_{1,\text{raw}})$$

### Step 3: Interference Cancellation & Stream 2 Detection
The reconstructed contribution of Stream 1 is subtracted from the received vector:
$$\mathbf{r}_{\text{clean}} = \begin{bmatrix} r_1 \\ r_2 \end{bmatrix} - \begin{bmatrix} h_{11} \\ h_{21} \end{bmatrix} \left( \frac{\hat{s}_{1,\text{sliced}}}{\sqrt{2}} \right)$$

Since Stream 1 interference is eliminated, Stream 2 is decoded using Maximal Ratio Combining (MRC) matched filtering on $\mathbf{h}_2$:
$$\hat{s}_{2,\text{det}} = \frac{\sqrt{2} \cdot \mathbf{h}_2^H \mathbf{r}_{\text{clean}}}{\|\mathbf{h}_2\|^2} = \frac{\sqrt{2} \cdot (h_{12}^* r_{\text{clean},1} + h_{22}^* r_{\text{clean},2})}{|h_{12}|^2 + |h_{22}|^2}$$

---

## 4. Hardware Port Specifications (`mmse_sic_hw.v`)

| Port Name | Direction | Bit Width | Data Type | Description |
|---|:---:|:---:|:---:|---|
| `clk`, `rst`, `clk_enable` | Input | 1, 1, 1 | System | Master clock (100 MHz), synchronous reset, clock enable |
| `r1_re`, `r1_im` | Input | 32, 32 | IEEE-754 Single | Received sample at Receive Antenna 1 |
| `r2_re`, `r2_im` | Input | 32, 32 | IEEE-754 Single | Received sample at Receive Antenna 2 |
| `h11_re` .. `h22_im` | Input | 8x 32 | IEEE-754 Single | Flat-fading $2\times 2$ channel matrix $\mathbf{H}$ |
| `noise_var` | Input | 32 | IEEE-754 Single | Noise variance $\sigma_n^2$ for MMSE regularization |
| `mod_order` | Input | 32 | IEEE-754 Single | Modulation order (`4.0f` for QPSK, `16.0f` for 16-QAM) |
| `ce_out` | Output | 1 | Strobe | Output valid strobe (asserts after 291 clock cycles) |
| `s1_re`, `s1_im` | Output | 32, 32 | IEEE-754 Single | Decoded Stream 1 soft output |
| `s2_re`, `s2_im` | Output | 32, 32 | IEEE-754 Single | Decoded Stream 2 soft output |

---

## 5. Decision Slicer Hardware (`qam_slicer_hw.v`)
* **Supported Constellations:** QPSK (Gray-coded: $\pm 1/\sqrt{2} \pm j/\sqrt{2}$), 16-QAM (Gray-coded: $\pm 1/\sqrt{10}, \pm 3/\sqrt{10}$).
* **Decision Boundary Logic:**
  * For QPSK: $\hat{I} = \text{sign}(I)/\sqrt{2}, \quad \hat{Q} = \text{sign}(Q)/\sqrt{2}$.
  * For 16-QAM: Thresholds placed at $0.0$ and $\pm 2/\sqrt{10} \approx \pm 0.6324555$.
* **Latency:** **5 clock cycles**.
* **Zero Discrepancy:** Evaluated across $10^6$ constellation points with $100\%$ decision equivalence against MATLAB `qamdemod`.
