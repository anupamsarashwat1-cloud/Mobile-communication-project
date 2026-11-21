# Subsystem 06: Top-Level ASIC Integration & System Verification
## Standalone 2x2 MIMO Baseband Processor ASIC (`SMVDU-MIMO-180`)
### Target Technology: SCL 180nm CMOS (1P6M) / Cadence gpdk180

---

## 1. Architectural Overview & Integration Scope
This directory contains the master top-level Verilog hardware integration wrapper (`mimo_baseband_top.v`) and its comprehensive self-checking verification testbench (`mimo_baseband_top_tb.v`).

`mimo_baseband_top.v` serves as the physical and logical boundary for the **SMVDU-MIMO-180** standalone ASIC, stitching together all 6 algorithmic cores generated via **MathWorks MATLAB HDL Coder** alongside an AXI4-Lite control/status register (CSR) interface, standard-cell floating-point arithmetic units, and streaming I/O buses.

```
                                  +-------------------------------------------------------------+
                                  |                 SMVDU-MIMO-180 TOP-LEVEL ASIC               |
                                  |                                                             |
   AXI4-Lite Bus (Control/Config) |  +--------------------+                                     |
   ------------------------------>|  |  AXI4-Lite Slave   |                                     |
                                  |  |   Register File    |<======+ (Status & Counters)         |
                                  |  +---------+----------+       |                             |
                                  |            |                  |                             |
   CSI Matrix H (h11..h22)        |            v                  |                             |
   Singular Values (sigma1, sigma2)  +--------------------+       |                             |
   Linear SNR & Noise Variance    |  | Adaptive Controller|-------+---> Mode Select & Alerts    |
   ------------------------------>|  | (Rank/Mode FSM)    |       |                             |
                                  |  +---------+----------+       |                             |
                                  |            |                  |                             |
                                  |            | Mode Select      |                             |
                                  |            v                  |                             |
   TX Symbols (s1, s2) ---------->|    [TX Mode Mux]              |                             |
                                  |     /          \              |                             |
                                  |    v            v             |                             |
                                  | +--------+  +---------+       |                             |
                                  | | Alamouti| | SVD/WF  |       |                             |
                                  | | Encoder | | Direct  |       |                             |
                                  | +---+----+  +----+----+       |                             |
                                  |     \            /            |                             |
                                  |      v          v             |                             |
                                  |   RF DAC Streams (TX1, TX2)   |                             |
                                  |   (Ant 1 & 2, Slots 1 & 2)    |                             |
                                  |                               |                             |
   RX Baseband ADC Streams ------>|    [RX Mode Demux]            |                             |
   (r1, r2 across Slots 1 & 2)    |     /          \              |                             |
                                  |    v            v             |                             |
                                  | +--------+  +---------+       |                             |
                                  | | Alamouti| | MMSE-SIC|       |                             |
                                  | | Combiner| | Non-Lin |       |                             |
                                  | +---+----+  +----+----+       |                             |
                                  |     \            /            |                             |
                                  |      v          v             |                             |
                                  |  +--------------------+       |                             |
                                  |  | QAM Decision Slicers|------+---> Sliced Outputs          |
                                  |  +--------------------+                                     |
                                  +-------------------------------------------------------------+
```

---

## 2. Master Module Pinout (`mimo_baseband_top.v`)

### System Control Interface
| Signal Name | Direction | Width | Domain | Description |
|---|:---:|:---:|:---:|---|
| `clk` | Input | 1-bit | Clock | Master digital clock (100 MHz nominal, 10.0 ns period) |
| `rst` | Input | 1-bit | Synchronous | Active-High synchronous master reset (HDL Coder standard) |
| `clk_enable` | Input | 1-bit | Synchronous | Global clock gating enable |

### AXI4-Lite Memory-Mapped Control Interface (Slave)
| Signal Name | Direction | Width | Description |
|---|:---:|:---:|---|
| `s_axi_awaddr` | Input | 32-bit | Write address bus |
| `s_axi_awvalid` / `s_axi_awready` | Handshake | 1-bit | Write address valid and ready handshakes |
| `s_axi_wdata` | Input | 32-bit | Write data bus |
| `s_axi_wstrb` | Input | 4-bit | Write byte strobes |
| `s_axi_wvalid` / `s_axi_wready` | Handshake | 1-bit | Write data valid and ready handshakes |
| `s_axi_bresp` / `s_axi_bvalid` / `s_axi_bready` | Handshake | 2/1/1-bit | Write response handshakes (returns `2'b00` OKAY) |
| `s_axi_araddr` | Input | 32-bit | Read address bus |
| `s_axi_arvalid` / `s_axi_arready` | Handshake | 1-bit | Read address valid and ready handshakes |
| `s_axi_rdata` | Output | 32-bit | Read data bus |
| `s_axi_rresp` / `s_axi_rvalid` / `s_axi_rready` | Handshake | 2/1/1-bit | Read response handshakes (returns `2'b00` OKAY) |

### Baseband Transmitter (TX) Interface
| Signal Name | Direction | Width | Encoding | Description |
|---|:---:|:---:|:---:|---|
| `tx_valid` | Input | 1-bit | Strobe | Input transmit symbol valid |
| `tx_ready` | Output | 1-bit | Strobe | Ready to accept next symbol pair |
| `tx_s1_re`, `tx_s1_im` | Input | 32-bit | IEEE-754 Single | Transmit symbol 1 (Real & Imaginary) |
| `tx_s2_re`, `tx_s2_im` | Input | 32-bit | IEEE-754 Single | Transmit symbol 2 (Real & Imaginary) |
| `tx_rf_valid` | Output | 1-bit | Strobe | Emitted RF DAC valid |
| `tx_ant1_t1_re`, `tx_ant1_t1_im` | Output | 32-bit | IEEE-754 Single | Antenna 1, Time Slot 1 baseband emission |
| `tx_ant2_t1_re`, `tx_ant2_t1_im` | Output | 32-bit | IEEE-754 Single | Antenna 2, Time Slot 1 baseband emission |
| `tx_ant1_t2_re`, `tx_ant1_t2_im` | Output | 32-bit | IEEE-754 Single | Antenna 1, Time Slot 2 baseband emission (STBC) |
| `tx_ant2_t2_re`, `tx_ant2_t2_im` | Output | 32-bit | IEEE-754 Single | Antenna 2, Time Slot 2 baseband emission (STBC) |

### Baseband Receiver (RX) Interface
| Signal Name | Direction | Width | Encoding | Description |
|---|:---:|:---:|:---:|---|
| `rx_valid` | Input | 1-bit | Strobe | Received ADC sample valid strobe |
| `rx_ant1_t1_re`, `rx_ant1_t1_im` | Input | 32-bit | IEEE-754 Single | Received sample at Ant 1, Slot 1 |
| `rx_ant2_t1_re`, `rx_ant2_t1_im` | Input | 32-bit | IEEE-754 Single | Received sample at Ant 2, Slot 1 |
| `rx_ant1_t2_re`, `rx_ant1_t2_im` | Input | 32-bit | IEEE-754 Single | Received sample at Ant 1, Slot 2 |
| `rx_ant2_t2_re`, `rx_ant2_t2_im` | Input | 32-bit | IEEE-754 Single | Received sample at Ant 2, Slot 2 |
| `rx_out_valid` | Output | 1-bit | Strobe | Receiver decoded symbol valid strobe |
| `rx_s1_hat_re`, `rx_s1_hat_im` | Output | 32-bit | IEEE-754 Single | Decided constellation point for Stream 1 |
| `rx_s2_hat_re`, `rx_s2_hat_im` | Output | 32-bit | IEEE-754 Single | Decided constellation point for Stream 2 |
| `rx_s1_raw_re`, `rx_s1_raw_im` | Output | 32-bit | IEEE-754 Single | Soft unquantized MMSE/MRC output 1 |
| `rx_s2_raw_re`, `rx_s2_raw_im` | Output | 32-bit | IEEE-754 Single | Soft unquantized MMSE/MRC output 2 |

### Channel State Information (CSI) & Telemetry Interface
| Signal Name | Direction | Width | Encoding | Description |
|---|:---:|:---:|:---:|---|
| `csi_h11_re` .. `csi_h22_im` | Input | 8x 32-bit | IEEE-754 Single | Flat-fading $2\times 2$ channel matrix $\mathbf{H}$ |
| `csi_sigma1`, `csi_sigma2` | Input | 2x 32-bit | IEEE-754 Single | Channel singular values ($\sigma_1 \ge \sigma_2$) |
| `sys_snr_linear` | Input | 32-bit | IEEE-754 Single | Operating SNR in linear scale ($10^{\text{SNR}_{\text{dB}}/10}$) |
| `sys_noise_var` | Input | 32-bit | IEEE-754 Single | Measured noise variance $\sigma_n^2$ |
| `telemetry_mode` | Output | 1-bit | Logic | Active mode (`0`: Alamouti STBC, `1`: Spatial Multiplexing) |
| `telemetry_kappa_high` | Output | 1-bit | Alert | `1` when $\sigma_1 > 4.5 \cdot \sigma_2$ (channel ill-conditioned) |
| `telemetry_active_rank` | Output | 32-bit | Integer | Number of active spatial streams (1 or 2) |
| `telemetry_p1_power` | Output | 32-bit | IEEE-754 Single | Water-filling power allocated to Stream 1 |
| `telemetry_p2_power` | Output | 32-bit | IEEE-754 Single | Water-filling power allocated to Stream 2 |
| `irq_frame_done` | Output | 1-bit | Strobe | Interrupt strobe asserted when RX output is valid |

---

## 3. Subsystem Instantiation & Latency Budget

| Instantiated Sub-Module | Source Verilog File | Pipeline Latency | Processing Role |
|---|---|:---:|---|
| `u_adaptive_controller` | `adaptive_controller_hw.v` | 12 cycles | Decides between STBC and SM using cross-multiplication |
| `u_water_filling` | `water_filling_hw.v` | 75 cycles | Unrolled dual-stage power optimization |
| `u_sq1`, `u_sq2` | `nfp_mul_single.v` | 5 cycles | Floating-point squarers for singular values |
| `u_alamouti_encoder` | `alamouti_encoder_hw.v` | 10 cycles | Orthogonal Space-Time Block Coding matrix creation |
| `u_alamouti_combiner` | `alamouti_combiner_hw.v` | 122 cycles | 8-MAC Maximal Ratio Combining engine |
| `u_mmse_sic` | `mmse_sic_hw.v` | 291 cycles | Gram matrix inversion, MMSE slicing, and interference subtraction |
| `u_slicer_stream1` | `qam_slicer_hw.v` | 5 cycles | Euclidean decision region mapping for Stream 1 |
| `u_slicer_stream2` | `qam_slicer_hw.v` | 5 cycles | Euclidean decision region mapping for Stream 2 |

### Critical Path Latency Analysis
* **Mode 0 (Alamouti STBC Diversity):**
  $$\text{Latency}_{\text{STBC}} = \text{Lat}_{\text{Combiner}} + \text{Lat}_{\text{Slicer}} = 122 + 5 = 127 \text{ clock cycles} = 1.27\ \mu\text{s} \text{ at } 100\text{ MHz}$$
* **Mode 1 (Spatial Multiplexing with MMSE-SIC):**
  $$\text{Latency}_{\text{SM}} = \text{Lat}_{\text{SIC}} + \text{Lat}_{\text{Slicer}} = 291 + 5 = 296 \text{ clock cycles} = 2.96\ \mu\text{s} \text{ at } 100\text{ MHz}$$
* Both modes easily operate well within the standard 5G NR OFDM symbol duration ($66.7\ \mu\text{s}$ for 15 kHz subcarrier spacing, or $8.33\ \mu\text{s}$ for 120 kHz SCS), guaranteeing real-time streaming line-rate performance.

---

## 4. Verification Testbench (`mimo_baseband_top_tb.v`)

The standalone verification testbench verifies:
1. **Clock & Reset Generation:** Provides a synchronous 100 MHz clock and tests active-high reset deassertion.
2. **AXI4-Lite Handshake:** Reads and writes Control and Configuration registers over `s_axi_*` buses.
3. **Well-Conditioned Channel Response:** Injecting $\sigma_1 = 1.2, \sigma_2 = 1.0, \text{SNR} = 15\text{ dB}$ verifies that `telemetry_mode` transitions to `1'b1` (Spatial Multiplexing).
4. **Ill-Conditioned Channel Response:** Injecting $\sigma_1 = 5.0, \sigma_2 = 0.5 \implies \kappa = 10.0 > 4.5$ verifies that `telemetry_mode` immediately falls back to `1'b0` (Alamouti STBC Diversity) with `telemetry_kappa_high = 1'b1`.
5. **Decoded Output Concordance:** Validates that decoded and sliced outputs align bit-for-bit with the golden MATLAB models.
