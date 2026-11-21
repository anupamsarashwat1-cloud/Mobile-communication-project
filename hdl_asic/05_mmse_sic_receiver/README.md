# Module 05: Ordered MMSE-SIC Detection Engine & QAM Slicer
## Generated Exclusively via MathWorks MATLAB HDL Coder
### Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)

---

## 1. Architectural Overview
This directory contains the synthesizable Verilog RTL for the non-linear Ordered MMSE Successive Interference Cancellation (V-BLAST) detection core and Euclidean nearest-neighbor constellation slicer, generated from [mmse_sic_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/mmse_sic_hw.m) and [qam_slicer_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/qam_slicer_hw.m) using **MATLAB HDL Coder**.

```
                           +------------------------+
   r1, r2 (re, im) ------->|                        |-----> s1_det (re, im)
   H (16 scalar inputs) -->|      mmse_sic_hw       |-----> s2_det (re, im)
   noise_var ------------->|   (MATLAB HDL Coder)   |
   mod_order (4 or 16) --->|                        |
   clk, rst, clk_enable -->|                        |
                           +------------------------+
```

---

## 2. Mathematical-to-Hardware Equivalence

### Step 1: Regularized Gram Matrix Formation & Closed-Form Inversion
$$\mathbf{G} = \mathbf{H}^H \mathbf{H} + 2 \sigma_n^2 \mathbf{I}_{2 \times 2}$$
$$\det(\mathbf{G}) = g_{11} g_{22} - |g_{12}|^2$$
$$\mathbf{G}^{-1} = \frac{1}{\det(\mathbf{G})} \begin{bmatrix} g_{22} & -g_{12} \\ -g_{21} & g_{11} \end{bmatrix}$$

### Step 2: Stream 1 MMSE Detection & Hard Constellation Slicing
$$\hat{s}_{1,\text{raw}} = \sqrt{2} \cdot \left(\mathbf{w}_1^T \mathbf{r}\right) \quad \text{where } \mathbf{w}_1^T = \text{Row}_1(\mathbf{G}^{-1} \mathbf{H}^H)$$
$$\hat{s}_{1,\text{sliced}} = \text{QAM\_Slicer}(\hat{s}_{1,\text{raw}})$$

### Step 3: Interference Cancellation & Stream 2 MRC Detection
$$\mathbf{r}_{\text{cancelled}} = \mathbf{r} - \mathbf{h}_1 \left(\frac{\hat{s}_{1,\text{sliced}}}{\sqrt{2}}\right)$$
$$\hat{s}_{2,\text{det}} = \frac{\sqrt{2} \cdot \mathbf{h}_2^H \mathbf{r}_{\text{cancelled}}}{\|\mathbf{h}_2\|^2}$$

* **Diversity Order:** $d = 2$ for both spatial streams.
* **Latency:** 291 clock cycles (pipelined Gram inversion, slicer feedback, cancellation, and MRC).
* **RTL Files:** `mmse_sic_hw.v`, `qam_slicer_hw.v`
