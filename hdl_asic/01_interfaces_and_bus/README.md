# Module 01: AXI4-Lite & AXI4-Stream Bus Interfaces
## Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)

---

## 1. Architectural Overview
This module implements the primary host control and data streaming interfaces for the standalone baseband ASIC:
1. **`mimo_axi4_lite_slave.v`**: Provides memory-mapped registers for host control (run/stop, mode override, threshold configuration, and status monitoring).
2. **`mimo_axis_stream_adapter.v`**: A pipelined skid buffer ensuring full-throughput (1 sample/clock) elastic streaming of 16-bit complex I/Q baseband samples without bubbles or stalls.

---

## 2. AXI4-Lite Register Memory Map

| Address Offset | Register Name | Access | Bitfields | Default Value | Description |
|---|---|:---:|---|:---:|---|
| `0x00` | `REG_CTRL` | R/W | `[0]` Core Enable<br>`[1]` Mode Override En<br>`[2]` Mode Override Val (0:STBC, 1:SM) | `0x00000001` | Primary chip enable and manual mode override controls |
| `0x04` | `REG_STATUS` | RO | `[0]` Core Busy<br>`[1]` Active Mode (0:STBC, 1:SM) | `0x00000000` | Real-time hardware execution status |
| `0x08` | `REG_KAPPA_THRESH`| R/W | `[15:0]` $\kappa_{\text{thresh}}$ in Q8.8 | `0x00000480` | Condition number threshold for mode switching ($4.5$) |
| `0x0C` | `REG_SNR_THRESH` | R/W | `[15:0]` $\text{SNR}_{\text{thresh}}$ in Q8.8 | `0x00000800` | SNR switching threshold ($8.0\text{ dB}$) |
| `0x10` | `REG_P_TOTAL` | R/W | `[15:0]` $P_{\text{total}}$ in Q2.14 | `0x00004000` | Total transmit power budget ($1.0$) |
| `0x14` | `REG_KAPPA_MEAS` | RO | `[15:0]` Instantaneous $\kappa$ in Q8.8 | `0x00000000` | Measured condition number from CORDIC SVD |
| `0x18` | `REG_ERR_COUNT` | RO | `[31:0]` Cumulative Bit Errors | `0x00000000` | Hardware parity/CRC verification counter |

---

## 3. Signal Interface Specifications

```
                           +---------------------------+
  s_axi_aclk ------------->|                           |
  s_axi_aresetn ---------->|                           |-----> reg_core_enable
  s_axi_awvalid/awready <->|    mimo_axi4_lite_slave   |-----> reg_mode_override_en
  s_axi_wvalid/wready   <->|                           |-----> reg_kappa_thresh_q8[15:0]
  s_axi_bvalid/bready   <->|                           |-----> reg_snr_thresh_q8[15:0]
  s_axi_arvalid/arready <->|                           |<----- status_core_busy
  s_axi_rvalid/rready   <->|                           |<----- status_active_mode
                           +---------------------------+
```

---

## 4. Verification & Synthesis Verification
* **Synthesis Compatibility:** Pure IEEE 1364-2001 Verilog; infers standard DFFs in SCL 180nm / Cadence gpdk180.
* **Clock Domain:** Synchronous with `clk_core` (100 MHz target).
* **Reset:** Synchronous active-low `rst_n`.
