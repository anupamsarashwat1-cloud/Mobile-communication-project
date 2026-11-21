# Module 03: Pipelined Water-Filling Power Allocation Core
## Generated Exclusively via MathWorks MATLAB HDL Coder
### Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)

---

## 1. Architectural Overview
This directory contains the synthesizable Verilog RTL for the 2-stream Water-Filling power optimization engine, generated directly from [water_filling_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/water_filling_hw.m) using **MATLAB HDL Coder**.

```
                             +------------------------+
   sigma1_sq -------------->|                        |-----> P1 (Allocated Power 1)
   sigma2_sq -------------->|    water_filling_hw    |-----> P2 (Allocated Power 2)
   P_total ---------------->|   (MATLAB HDL Coder)   |-----> active_rank (1 or 2)
   noise_var -------------->|                        |
   clk, rst, clk_enable --->|                        |
                             +------------------------+
```

---

## 2. Mathematical-to-Hardware Equivalence

The dynamic iterative while-loop of the textbook water-filling algorithm was completely unrolled into a deterministic 2-stage pipelined comparator engine:

### Stage 1: Dual-Stream Water Level Computation
Computes inverse subchannel SNRs:
$$\alpha_1 = \frac{\sigma_n^2}{\sigma_1^2}, \quad \alpha_2 = \frac{\sigma_n^2}{\sigma_2^2}$$
Water level assuming Rank 2:
$$\mu = \frac{P_{\text{total}} + \alpha_1 + \alpha_2}{2}$$

### Stage 2: Non-Negativity Decision & Clamping
$$P_2 = \mu - \alpha_2$$
* If $P_2 > 0$: Both streams receive power ($P_1 = \mu - \alpha_1, P_2 = \mu - \alpha_2$), $\text{rank} = 2$.
* If $P_2 \le 0$: Stream 2 is deactivated ($P_2 = 0, P_1 = P_{\text{total}}$), $\text{rank} = 1$.

* **Latency:** 75 clock cycles (pipelined divider, adder, and comparator tree).
* **Clock Target:** 100 MHz on SCL 180nm / Cadence gpdk180.
* **RTL File:** `water_filling_hw.v`
