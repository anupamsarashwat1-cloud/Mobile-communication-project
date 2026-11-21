# Module 02: Alamouti 2x2 STBC Transceiver Core
## Generated Exclusively via MathWorks MATLAB HDL Coder
### Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)

---

## 1. Architectural Overview
This directory contains the synthesizable Verilog RTL for the 2x2 Alamouti Space-Time Block Coding (STBC) transmit and receive engines, automatically generated from [alamouti_encoder_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/alamouti_encoder_hw.m) and [alamouti_combiner_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/alamouti_combiner_hw.m) using **MATLAB HDL Coder**.

```
                           +------------------------+
   s1 (re, im) ----------->|                        |-----> x1_t1 (re, im)
   s2 (re, im) ----------->|   alamouti_encoder_hw  |-----> x2_t1 (re, im)
   clk, rst, clk_enable -->|   (MATLAB HDL Coder)   |-----> x1_t2 (re, im)
                           |                        |-----> x2_t2 (re, im)
                           +------------------------+
```

---

## 2. Mathematical-to-Hardware Equivalence

### Transmitter: Space-Time Block Encoder
Maps two consecutive modulation symbols ($s_1, s_2$) across 2 transmit antennas and 2 time slots:
$$\mathbf{X} = \frac{1}{\sqrt{2}} \begin{bmatrix} s_1 & -s_2^* \\ s_2 & s_1^* \end{bmatrix}$$
* **Latency:** 10 clock cycles (pipelined IEEE-754 single-precision floating-point).
* **RTL File:** `alamouti_encoder_hw.v`

### Receiver: Maximal Ratio Combining (MRC) Engine
Reconstructs transmitted symbols from received samples across 2 receive antennas ($r_1, r_2$) and 2 time slots:
$$\hat{s}_1 = \frac{\sqrt{2} \cdot \left(h_{11}^* r_1(1) + h_{21}^* r_2(1) + h_{12} r_1^*(2) + h_{22} r_2^*(2)\right)}{\|\mathbf{H}\|_F^2}$$
$$\hat{s}_2 = \frac{\sqrt{2} \cdot \left(h_{12}^* r_1(1) + h_{22}^* r_2(1) - h_{11} r_1^*(2) - h_{21} r_2^*(2)\right)}{\|\mathbf{H}\|_F^2}$$
* **Diversity Order:** $d = 4$
* **Latency:** 122 clock cycles (pipelined divider and complex MAC tree).
* **RTL File:** `alamouti_combiner_hw.v`

---

## 3. Generated Hardware Modules

| Verilog File | Role | Generation Source | Synthesis Constraints |
|---|---|---|---|
| **`alamouti_encoder_hw.v`** | 2-Slot STBC Matrix Mapper | `alamouti_encoder_hw.m` | Synchronous reset, Native Floating Point |
| **`alamouti_combiner_hw.v`** | 8-MAC MRC Receiver Engine | `alamouti_combiner_hw.m` | Synchronous reset, Generic RAM, Pipelined |
| `nfp_mul_single.v` | IEEE-754 Single Multiplier | HDL Coder NFP Library | Standard-cell synthesizable |
| `nfp_add_single.v` | IEEE-754 Single Adder | HDL Coder NFP Library | Standard-cell synthesizable |
| `nfp_sub_single.v` | IEEE-754 Single Subtractor | HDL Coder NFP Library | Standard-cell synthesizable |
| `nfp_div_single.v` | IEEE-754 Single Divider | HDL Coder NFP Library | Standard-cell synthesizable |
| `nfp_uminus_single.v` | Unary Sign Inverter | HDL Coder NFP Library | Pure bit-level sign toggle |
