# Consolidated Synthesizable Verilog Library (`build_rtl/`)
## Complete Hardware Module Reference Guide
### Standalone 2x2 MIMO Baseband Processor ASIC (`SMVDU-MIMO-180`)
### Target Fabrication: SCL 180nm CMOS (1P6M) / Cadence generic 180nm PDK (`gpdk180`)

---

## 1. Overview of Consolidated RTL Library
This directory contains the complete collection of **17 synthesizable Verilog modules** generated programmatically by **MathWorks MATLAB HDL Coder (Release 26.2)**. All algorithmic logic has been generated from static-typed `%#codegen` MATLAB wrapper functions, using IEEE-754 Single-Precision Native Floating Point (NFP) synthesis.

Every design file in this directory conforms to **IEEE 1364-2001 Verilog**, uses synchronous active-high resets, and synthesizes directly onto standard-cell libraries using **Cadence Genus** with 0 errors and 0 warnings.

---

## 2. Exhaustive Design File Directory & Module Details

```
build_rtl/
├── 1.  adaptive_controller_hw.v   - Real-Time Rank Adaptation Comparator Engine
├── 2.  alamouti_combiner_hw.v     - 8-MAC Maximal Ratio Combining (MRC) STBC Receiver
├── 3.  alamouti_encoder_hw.v      - 2-Time-Slot Space-Time Block Transmit Encoder
├── 4.  mmse_sic_hw.v              - Non-Linear Ordered MMSE-SIC Detection Processor
├── 5.  qam_slicer_hw.v            - Euclidean Nearest-Neighbor Constellation Slicer
├── 6.  water_filling_hw.v         - Unrolled 2-Stage Water-Filling Power Allocator
├── 7.  nfp_add_single.v           - Pipelined IEEE-754 Single-Precision Adder Core
├── 8.  nfp_sub_single.v           - Pipelined IEEE-754 Single-Precision Subtractor Core
├── 9.  nfp_mul_single.v           - Pipelined IEEE-754 Single-Precision Multiplier Core
├── 10. nfp_div_single.v           - Pipelined IEEE-754 Single-Precision Divider Core
├── 11. nfp_recip_single.v         - Pipelined IEEE-754 Single-Precision Reciprocal Core
├── 12. nfp_relop_single.v         - IEEE-754 Relational Operator (Greater Than)
├── 13. nfp_relop_single_block.v   - IEEE-754 Relational Operator Block (Comparator Variant 1)
├── 14. nfp_relop_single_block1.v  - IEEE-754 Relational Operator Block (Comparator Variant 2)
├── 15. nfp_relop_single_block2.v  - IEEE-754 Relational Operator Block (Comparator Variant 3)
├── 16. nfp_gain_pow2_single.v     - IEEE-754 Single-Precision Power-of-2 Scaling Engine
└── 17. nfp_uminus_single.v        - IEEE-754 Unary Sign Inverter Core
```

---

### Detailed Specification for Each Design File

#### 1. `adaptive_controller_hw.v`
* **Source MATLAB Function:** `hdl_src_matlab/adaptive_controller_hw.m`
* **Role:** Evaluates channel condition number ($\kappa = \sigma_1/\sigma_2$) and operational SNR against predefined thresholds in real time to select the optimum transmission mode and rank.
* **Microarchitecture:** Employs an unrolled cross-multiplication pipeline (`sigma1 > kappa_thresh * sigma2`) to eliminate hardware division overhead.
* **Pipeline Latency:** **12 clock cycles** (120 ns @ 100 MHz).
* **Port Interface:**
  * Inputs: `clk`, `rst`, `clk_enable`, `sigma1` (32b single), `sigma2` (32b single), `snr_linear` (32b single), `kappa_thresh` (32b single), `snr_thresh_linear` (32b single).
  * Outputs: `ce_out`, `selected_mode` (32b single: `0.0` for STBC, `1.0` for SM), `kappa_is_high` (1-bit flag), `active_streams` (32b single: `1.0` or `2.0`).

---

#### 2. `alamouti_combiner_hw.v`
* **Source MATLAB Function:** `hdl_src_matlab/alamouti_combiner_hw.m`
* **Role:** Implements the $2\times 2$ Alamouti Maximal Ratio Combining (MRC) receiver algorithm, decoding symbols across 2 receive antennas and 2 time slots to achieve full diversity order $d=4$.
* **Microarchitecture:** Contains an 8-MAC complex cross-multiplier tree followed by Frobenius norm scaling ($\|\mathbf{H}\|_F^2$) and an IEEE-754 floating-point divider.
* **Pipeline Latency:** **122 clock cycles** (1.22 μs @ 100 MHz).
* **Port Interface:**
  * Inputs: `clk`, `rst`, `clk_enable`, received signals `r1_t1_re`, `r1_t1_im`, `r2_t1_re`, `r2_t1_im`, `r1_t2_re`, `r1_t2_im`, `r2_t2_re`, `r2_t2_im`, and CSI matrix elements `h11_re`..`h22_im` (all 32b single).
  * Outputs: `ce_out`, decoded soft symbols `s1_re`, `s1_im`, `s2_re`, `s2_im` (all 32b single).

---

#### 3. `alamouti_encoder_hw.v`
* **Source MATLAB Function:** `hdl_src_matlab/alamouti_encoder_hw.m`
* **Role:** Encodes two consecutive information symbols ($s_1, s_2$) into the orthogonal Alamouti space-time code matrix across two transmit antennas and two time slots:
  $$\mathbf{X} = \frac{1}{\sqrt{2}} \begin{bmatrix} s_1 & -s_2^* \\ s_2 & s_1^* \end{bmatrix}$$
* **Microarchitecture:** Pipelined complex conjugation, sign negation, and $1/\sqrt{2}$ power normalization multipliers.
* **Pipeline Latency:** **10 clock cycles** (100 ns @ 100 MHz).
* **Port Interface:**
  * Inputs: `clk`, `rst`, `clk_enable`, `s1_re`, `s1_im`, `s2_re`, `s2_im` (32b single).
  * Outputs: `ce_out`, `x1_t1_re`, `x1_t1_im`, `x2_t1_re`, `x2_t1_im`, `x1_t2_re`, `x1_t2_im`, `x2_t2_re`, `x2_t2_im` (all 32b single).

---

#### 4. `mmse_sic_hw.v`
* **Source MATLAB Function:** `hdl_src_matlab/mmse_sic_hw.m`
* **Role:** Ordered Non-Linear MMSE Successive Interference Cancellation (V-BLAST) detection engine for spatial multiplexing mode. Reconstructs both spatial streams at full spectral efficiency.
* **Microarchitecture:**
  1. Computes regularized Gram matrix $\mathbf{G} = \mathbf{H}^H\mathbf{H} + 2\sigma_n^2\mathbf{I}_{2\times 2}$.
  2. Evaluates closed-form determinant $\det(\mathbf{G})$ and inverts $\mathbf{G}$.
  3. Detects Stream 1 via MMSE filtering, slices it to the nearest constellation point.
  4. Subtracts Stream 1 interference from received vector: $\mathbf{r}_{\text{canc}} = \mathbf{r} - \mathbf{h}_1 \hat{s}_1$.
  5. Decodes Stream 2 via matched filtering on the interference-free vector.
* **Pipeline Latency:** **291 clock cycles** (2.91 μs @ 100 MHz).
* **Port Interface:**
  * Inputs: `clk`, `rst`, `clk_enable`, `r1_re`, `r1_im`, `r2_re`, `r2_im`, `h11_re`..`h22_im`, `noise_var`, `mod_order` (all 32b single).
  * Outputs: `ce_out`, `s1_re`, `s1_im`, `s2_re`, `s2_im` (all 32b single).

---

#### 5. `qam_slicer_hw.v`
* **Source MATLAB Function:** `hdl_src_matlab/qam_slicer_hw.m`
* **Role:** Hard-decision Euclidean nearest-neighbor constellation slicer supporting BPSK, QPSK, and 16-QAM modulations.
* **Microarchitecture:** Pipelined relational decision tree comparing normalized In-Phase and Quadrature components against threshold boundaries ($\pm 2/\sqrt{10}, 0$).
* **Pipeline Latency:** **5 clock cycles** (50 ns @ 100 MHz).
* **Port Interface:**
  * Inputs: `clk`, `rst`, `clk_enable`, `r_i` (32b single), `r_q` (32b single), `mod_order` (32b single).
  * Outputs: `ce_out`, sliced coordinates `s_hat_i` (32b single), `s_hat_q` (32b single).

---

#### 6. `water_filling_hw.v`
* **Source MATLAB Function:** `hdl_src_matlab/water_filling_hw.m`
* **Role:** Dynamically allocates transmit power across the two spatial eigenmodes to maximize Shannon channel capacity.
* **Microarchitecture:** Fully unrolled 2-stage pipeline calculating water level $\mu = (P_{\text{total}} + \sigma_n^2/\sigma_1^2 + \sigma_n^2/\sigma_2^2)/2$, checking $P_2 = \mu - \sigma_n^2/\sigma_2^2$, and clamping $P_2 = 0, P_1 = P_{\text{total}}$ if Stream 2 power falls non-positive.
* **Pipeline Latency:** **75 clock cycles** (750 ns @ 100 MHz).
* **Port Interface:**
  * Inputs: `clk`, `rst`, `clk_enable`, `sigma1_sq` (32b single), `sigma2_sq` (32b single), `P_total` (32b single), `noise_var` (32b single).
  * Outputs: `ce_out`, `P1` (32b single), `P2` (32b single), `active_rank` (32b single).

---

#### 7. `nfp_add_single.v`
* **Role:** IEEE-754 Single-Precision Floating-Point Pipelined Adder.
* **Format:** 1 sign bit, 8 exponent bits (bias 127), 23 mantissa bits (implicit leading 1).
* **Features:** Pipelined exponent difference computation, mantissa alignment shifter, integer adder, leading-zero detector (LZD), normalization shifter, and round-to-nearest-even logic.
* **Latency:** Fully pipelined across 7 clock cycles for 100 MHz timing closure in SCL 180nm.

---

#### 8. `nfp_sub_single.v`
* **Role:** IEEE-754 Single-Precision Floating-Point Pipelined Subtractor.
* **Features:** Shares adder architecture with inverted sign on the subtrahend operand; fully handles sign cancellation and denormal flushing.
* **Latency:** Pipelined across 7 clock cycles.

---

#### 9. `nfp_mul_single.v`
* **Role:** IEEE-754 Single-Precision Floating-Point Pipelined Multiplier.
* **Microarchitecture:** Contains a $24 \times 24$-bit unsigned integer array multiplier (pipelined across 3 stages), exponent adder with bias correction, and mantissa normalization/rounding stage.
* **Latency:** Pipelined across 5 clock cycles.

---

#### 10. `nfp_div_single.v`
* **Role:** IEEE-754 Single-Precision Floating-Point Pipelined Divider.
* **Microarchitecture:** Radix-2 / Radix-4 non-restoring divider computing 27 bits of quotient (including guard, round, and sticky bits), exponent subtractor with bias restoration, and exceptional value handling ($\pm \infty, \text{NaN}, \text{underflow}$).
* **Latency:** Pipelined across 33 clock cycles.

---

#### 11. `nfp_recip_single.v`
* **Role:** IEEE-754 Single-Precision Floating-Point Reciprocal Generator ($1/x$).
* **Microarchitecture:** Look-Up Table (LUT) seed generator combined with 2 iterations of Newton-Raphson polynomial refinement for single-precision accuracy ($\approx 10^{-7}$).
* **Latency:** Pipelined across 22 clock cycles.

---

#### 12-15. `nfp_relop_single.v`, `nfp_relop_single_block.v`, `_block1.v`, `_block2.v`
* **Role:** IEEE-754 Floating-Point Relational Comparators ($>, \ge, <, \le, ==$).
* **Microarchitecture:** Separates comparison into sign evaluation, exponent comparison, and magnitude inspection. Handles signed zero ($+0 == -0$) and NaN comparisons according to IEEE-754-2008 semantics.
* **Latency:** 1 to 2 clock cycles.

---

#### 16. `nfp_gain_pow2_single.v`
* **Role:** Single-Precision Power-of-2 Scaling Engine ($x \cdot 2^k$).
* **Microarchitecture:** Direct exponent modification unit without invoking a full multiplier. Adds the integer scale $k$ directly to the 8-bit biased exponent with saturation detection.
* **Latency:** 1 clock cycle.

---

#### 17. `nfp_uminus_single.v`
* **Role:** IEEE-754 Unary Floating-Point Negation ($-x$).
* **Microarchitecture:** Pure zero-latency bit-level XOR on bit [31] (sign bit).
* **Latency:** 0 clock cycles (pure combinational standard-cell inverter).
