# Functional Block Diagram Specification
## Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)

---

## 1. Top-Level Functional Block Architecture

```mermaid
flowchart TD
    subgraph PADS_NORTH["North Pad Frame (Host & Control)"]
        CLK_PAD["CLK_IN (100MHz)"]
        RST_PAD["RST_N (Active-Low)"]
        HOST_BUS["AXI4-Lite Host Interface<br/>(awaddr, wdata, araddr, rdata)"]
    end

    subgraph CLK_RST["Clock & Reset Subsystem"]
        CLK_TREE["Clock Buffer Tree & ICG"]
        RST_SYNC["2-Stage De-assertion<br/>Reset Synchronizer"]
    end

    subgraph HOST_REGS["Host Configuration & Status (AXI4-Lite Slave)"]
        REG_CTRL["Control: Enable, Mode Override"]
        REG_THRESH["Thresholds: kappa_th (4.5), SNR_th (8.0dB)"]
        REG_POWER["Power Budget: P_total (Q2.14)"]
        REG_STAT["Status: Active Mode, kappa_meas, Err_Count"]
    end

    subgraph PADS_SOUTH_RX["South Pad Frame (RF Baseband In)"]
        RX0_PAD["RX0 I/Q (16-bit Q1.15)"]
        RX1_PAD["RX1 I/Q (16-bit Q1.15)"]
    end

    subgraph RX_DFE["Receiver Digital Front-End (DFE)"]
        RX_FIFO["Dual Elastic Input FIFOs"]
        RX_DC["DC Offset & Gain Imbalance Core"]
    end

    subgraph CHANNEL_ENGINE["Channel Engine & Adaptive Mode FSM"]
        H_BUF["Channel Matrix Buffer H (2x2)"]
        CORDIC_SVD["16-Stage CORDIC SVD Engine<br/>H = U * Sigma * V^H"]
        EVAL_FSM["Adaptive Mode Controller FSM<br/>Checks: sigma1 > 4.5*sigma2 OR SNR < 8dB"]
    end

    subgraph TX_DATAPATH["Transmit Processing Engine"]
        TX_FIFO["Input Symbol Stream FIFO"]
        TX_MAP["QAM Constellation Mapper<br/>(QPSK, 16-QAM, 64-QAM)"]
        subgraph TX_MODES["Mode-Gated Transmit Path"]
            STBC_ENC["Alamouti 2x2 STBC Encoder<br/>(2 Antennas x 2 Time Slots)"]
            SVD_PREC["SVD Precoding Matrix (V)<br/>+ Water-Filling Power Scaling (P*)"]
        end
        TX_MUX["TX Mode Multiplexer"]
    end

    subgraph RX_DATAPATH["Receive Detection Engine"]
        subgraph RX_MODES["Dual Receive Engines"]
            MRC_COMB["Alamouti MRC Combiner<br/>(8 Complex MACs + Norm LUT)"]
            SIC_CORE["MMSE-SIC / SVD Detector<br/>(U' Combiner + V-BLAST Slicer)"]
        end
        DEMAP["Hard Decision QAM Slicers<br/>& Demapper to Bitstream"]
        OUT_FIFO["Output Stream FIFO"]
    end

    subgraph PADS_SOUTH_TX["South Pad Frame (Baseband Out / Host Data)"]
        TX0_PAD["TX0 I/Q (16-bit Q1.15)"]
        TX1_PAD["TX1 I/Q (16-bit Q1.15)"]
        HOST_OUT["AXI4-Stream Master<br/>Demodulated Output Data"]
    end

    %% Connections
    CLK_PAD --> CLK_TREE
    RST_PAD --> RST_SYNC
    HOST_BUS --> HOST_REGS

    PADS_SOUTH_RX --> RX_DFE
    RX_DFE --> H_BUF
    H_BUF --> CORDIC_SVD
    CORDIC_SVD --> EVAL_FSM
    HOST_REGS --> EVAL_FSM

    TX_FIFO --> TX_MAP
    TX_MAP --> TX_MODES
    EVAL_FSM -- "mode_sel (STBC=0, SM=1)" --> TX_MUX
    TX_MODES --> TX_MUX
    TX_MUX --> PADS_SOUTH_TX

    RX_DFE --> RX_MODES
    CORDIC_SVD -- "Unitary U', Singular Values" --> RX_MODES
    EVAL_FSM -- "mode_sel" --> RX_MODES
    RX_MODES --> DEMAP
    DEMAP --> OUT_FIFO
    OUT_FIFO --> HOST_OUT
```

---

## 2. Microarchitectural Block Breakdown

### Block 1: Transmit Engine (TX)
* **Symbol FIFO & Mapper:** Ingests raw data bits, maps to Gray-coded QPSK, 16-QAM, or 64-QAM constellations with unit average power ($E_s = 1$).
* **Alamouti STBC 2x2 Encoder:**
  $$\mathbf{X} = \frac{1}{\sqrt{2}} \begin{bmatrix} s_1 & -s_2^* \\ s_2 & s_1^* \end{bmatrix}$$
  * Operates with 2-clock latency using shift registers, sign negators, and multiplexers.
* **SVD Precoding & Water-Filling:**
  $$\mathbf{x} = \mathbf{V} \begin{bmatrix} \sqrt{P_1^*} s_1 \\ \sqrt{P_2^*} s_2 \end{bmatrix}$$
  * 4 complex multipliers scaling spatial streams by right unitary matrix $\mathbf{V}$ and allocated power $P_i^*$.

### Block 2: 16-Stage CORDIC SVD Decomposition Engine
* Computes singular values $\sigma_1, \sigma_2$ and unitary matrices $\mathbf{U}^H, \mathbf{V}$ from channel matrix $\mathbf{H}$ using two-sided iterative Givens rotations:
  $$\mathbf{H}_{k+1} = \mathbf{R}(\theta_L)^H \mathbf{H}_k \mathbf{R}(\theta_R)$$
* **Hardware Profile:** 16 unrolled coordinate rotation stages, 0 multipliers, shift-and-add logic only, fixed latency of 16 clock cycles.

### Block 3: Adaptive Rank-Switching Controller (FSM)
* Evaluates instantaneous channel condition number and SNR:
  $$\text{Condition: } \sigma_1 > 4.5 \cdot \sigma_2 \quad \text{OR} \quad \text{SNR} < 8.0\text{ dB}$$
* If true $\implies \text{mode\_sel} = 0$ (Alamouti STBC Diversity Mode).
* If false $\implies \text{mode\_sel} = 1$ (SVD-WF Spatial Multiplexing Mode).
* Replaces floating-point division with a single-cycle cross-multiplication comparator.

### Block 4: Advanced Detection Engine (RX)
* **Alamouti MRC Combiner:**
  $$\hat{s}_1 = \frac{h_{11}^* r_1(1) + h_{21}^* r_2(1) + h_{12} r_1^*(2) + h_{22} r_2^*(2)}{\|\mathbf{H}\|_F^2 / \sqrt{2}}$$
  * 8 complex multiply-accumulators (MACs) paired with a 256-word reciprocal normalization LUT.
* **MMSE-SIC Detector:**
  * Cancels detected stream $\hat{s}_1$ from received vector: $\mathbf{r}_{\text{cancelled}} = \mathbf{r} - \mathbf{h}_1 \hat{s}_1$.
  * Detects stream 2 via Maximal Ratio Combining (MRC), achieving diversity order $d=2$ on both spatial streams.

---

## 3. Clock & Reset Management
* **Single Primary Clock:** `clk` (100 MHz target, period $10.0\text{ ns}$).
* **Integrated Clock Gating (ICG):** Unused datapath modes (e.g. STBC during SM mode) are automatically clock-gated to conserve dynamic power.
* **Reset Strategy:** Synchronous core reset generated via an active-low asynchronous reset pad with a 2-stage de-assertion synchronizer.
