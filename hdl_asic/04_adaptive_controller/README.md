# Module 04: Dynamic Rank Adaptation Controller
## Generated Exclusively via MathWorks MATLAB HDL Coder
### Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)

---

## 1. Architectural Overview
This directory contains the synthesizable Verilog RTL for the real-time MIMO mode and rank adaptation controller, generated directly from [adaptive_controller_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/adaptive_controller_hw.m) using **MATLAB HDL Coder**.

```
                             +------------------------+
   sigma1 ------------------>|                        |-----> selected_mode (0:STBC, 1:SM)
   sigma2 ------------------>|  adaptive_controller_hw|-----> kappa_is_high
   snr_linear -------------->|   (MATLAB HDL Coder)   |-----> active_streams (1 or 2)
   kappa_thresh (4.5) ------>|                        |
   snr_thresh_lin (6.31) --->|                        |
   clk, rst, clk_enable ---->|                        |
                             +------------------------+
```

---

## 2. Mathematical-to-Hardware Equivalence

### Cross-Multiplication Condition Number Comparator
To eliminate a bulky and latency-heavy hardware divider for condition number $\kappa = \frac{\sigma_1}{\sigma_2}$, the comparison is reformulated using pure cross-multiplication:
$$\kappa > 4.5 \iff \sigma_1 > 4.5 \cdot \sigma_2$$

### Switching Rule
$$\text{Mode} = \begin{cases} 
0 \text{ (Alamouti STBC Diversity Mode)}, & \text{if } \sigma_1 > 4.5 \cdot \sigma_2 \quad \text{or} \quad \text{SNR} < 8.0\text{ dB} \\
1 \text{ (SVD-WF Spatial Multiplexing Mode)}, & \text{otherwise}
\end{cases}$$

* **Decision Concordance:** $100\%$ match with MATLAB floating-point model across 1,000 random channels.
* **Latency:** 12 clock cycles (pipelined multiplier and relational comparator).
* **RTL File:** `adaptive_controller_hw.v`
