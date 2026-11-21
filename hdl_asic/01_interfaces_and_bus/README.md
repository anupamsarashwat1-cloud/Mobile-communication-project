# Subsystem 01: Host Bus Interfaces & On-Chip Interconnect
## Complete Synthesizable Verilog RTL & Architectural Reference
### Standalone 2x2 MIMO Baseband Processor ASIC (`SMVDU-MIMO-180`)
### Target Technology: SCL 180nm CMOS (1P6M) / Cadence generic 180nm PDK (`gpdk180`)

---

## 1. Subsystem Architecture & Functional Role
The **Host Bus Interfaces & On-Chip Interconnect** subsystem (`01_interfaces_and_bus/`) provides the standard control and streaming interconnect infrastructure for the standalone **SMVDU-MIMO-180** processor. It bridges external host processors (such as an off-chip RISC-V controller or FPGA host) and high-speed data converters (RF ADCs and DACs) to the internal baseband algorithmic engines.

```
                               +-------------------------------------------------------+
                               |     SUBSYSTEM 01: BUS INTERFACES & INTERCONNECT       |
                               |                                                       |
   Host AXI4-Lite Master ----->| +---------------------------------------------------+ |
   (Address, Data, Control)    | |             mimo_interconnect_crossbar.v          | |
                               | |              (1-to-2 AXI4-Lite Router)            | |
                               | +-------------------------+-------------------------+ |
                               |                           |                           |
                               |          0x4000_0xxx      |      0x4000_1xxx          |
                               |                           v                           v
                               |             +---------------------------+   +---------------+
                               |             |    mimo_axi4_lite_slave   |   | CSI Memory    |
                               |             | (Control, Status & Config)|   | Buffer Space  |
                               |             +-------------+-------------+   +---------------+
                               |                           |                           |
                               |                           v                           |
                               |             Core Run/Stop, Thresholds, CSRs           |
                               |                                                       |
   ADC Ingest / DAC Egress --->| +---------------------------------------------------+ |
   (64-bit Complex I/Q Stream) | |             mimo_axis_stream_adapter.v            | |
                               | |              (Elastic Skid Buffer Slice)          | |
                               | +---------------------------------------------------+ |
                               +-------------------------------------------------------+
```

---

## 2. Directory Verilog Design Files & Descriptions

| Design File (`.v`) | Module Name | Pipeline Latency | Functional & Standard-Cell Description |
|---|---|:---:|---|
| **`mimo_axi4_lite_slave.v`** | `mimo_axi4_lite_slave` | 1 cycle read/write | Memory-mapped register file providing control flags, mode override, IEEE-754 switching thresholds, and real-time telemetry. |
| **`mimo_axis_stream_adapter.v`**| `mimo_axis_stream_adapter`| 1 cycle | Full-throughput elastic skid buffer. Decouples timing paths between ADC/DAC converters and baseband pipelines, preventing stalls and bubbles. |
| **`mimo_interconnect_crossbar.v`**| `mimo_interconnect_crossbar`| 0 cycles (comb steering) | 1-to-2 AXI4-Lite interconnect crossbar router. Routes transactions between baseband CSR registers and CSI parameter memory space. |

---

## 3. Detailed Specifications & Microarchitecture

### 1. `mimo_axi4_lite_slave.v`
Implements the official ARM AMBA AXI4-Lite specification with non-blocking write and read state machines:
* **Write Channel Handshake:** Decoupled `awready` and `wready` handshakes allow simultaneous or independent address and data phases.
* **Read Channel Handshake:** Single-cycle read response latency with registered `rdata` to maximize setup time in SCL 180nm standard cells.
* **Byte Strobes (`s_axi_wstrb`):** Full 4-byte granular write support for control registers.
* **Diagnostic Hardware Counters:** Integrates a 32-bit execution cycle counter and a hardware frame completion counter.

#### Register Memory Map (Base: `0x4000_0000`)
| Address Offset | Register Name | Access | Reset Value | Description |
|---|---|:---:|:---:|---|
| `0x00` | `REG_CONTROL` | R/W | `0x0000_0001` | **[0]:** Core Enable (`1`: Run, `0`: Gate)<br/>**[1]:** Mode Override En (`1`: Force Mode)<br/>**[2]:** Forced Mode Val (`0`: STBC, `1`: SM)<br/>**[3]:** Soft Pipeline Reset Strobe |
| `0x04` | `REG_STATUS` | RO | `0x0000_0001` | **[0]:** Hardware Core Ready<br/>**[1]:** Active Operating Mode (`0`: STBC, `1`: SM)<br/>**[2]:** High Condition Number Warning ($\kappa > 4.5$)<br/>**[4:3]:** Active Spatial Streams (`2'b01`: 1, `2'b10`: 2) |
| `0x08` | `REG_KAPPA_THRESH`| R/W | `0x4090_0000` | IEEE-754 Single condition number threshold (Default: `4.5f`) |
| `0x0C` | `REG_SNR_THRESH` | R/W | `0x40CA_3D71` | IEEE-754 Single linear SNR switching threshold (Default: `6.31f` = $8.0\text{ dB}$) |
| `0x10` | `REG_TOTAL_POWER` | R/W | `0x3F80_0000` | IEEE-754 Single total power budget $P_{\text{total}}$ (Default: `1.0f`) |
| `0x14` | `REG_MOD_ORDER` | R/W | `0x4080_0000` | IEEE-754 Single modulation order (`4.0f` for QPSK, `16.0f` for 16-QAM) |
| `0x18` | `REG_TELEMETRY_P1`| RO | `0x3F00_0000` | IEEE-754 Single power currently allocated to Stream 1 ($P_1$) |
| `0x1C` | `REG_TELEMETRY_P2`| RO | `0x3F00_0000` | IEEE-754 Single power currently allocated to Stream 2 ($P_2$) |
| `0x20` | `REG_CYCLE_COUNT` | RO | `0x0000_0000` | 32-bit continuous hardware execution clock counter |
| `0x24` | `REG_FRAME_COUNT` | RO | `0x0000_0000` | 32-bit hardware frame completion event counter |

---

### 2. `mimo_axis_stream_adapter.v`
High-speed continuous streaming of 64-bit I/Q baseband samples (32-bit IEEE single In-Phase + 32-bit IEEE single Quadrature) often creates critical timing paths when backpressure (`tready`) propagates combinationally through long pipeline stages.
* **Skid Buffer Principle:** When downstream `m_axis_tready` deasserts, incoming samples on `s_axis_tdata` are absorbed into a secondary shadow register (`skid_data`) while `s_axis_tready` remains asserted for that clock cycle.
* **Zero Bubble Insertion:** Guarantees sustained $100\%$ bandwidth throughput ($1.0\ \text{sample/cycle} = 6.4\ \text{Gbps}$ aggregate bus bandwidth at 100 MHz).
* **Timing Isolation:** Breaks the combinational loop from `m_axis_tready` to `s_axis_tready`, preventing setup timing violations during physical place-and-route.

---

### 3. `mimo_interconnect_crossbar.v`
A low-overhead, synthesizable AXI4-Lite crossbar interconnect that enables multi-peripheral memory mapping on the chip:
* **Address Decoding:** Uses Address bit `[12]` to steer transactions:
  * `0x4000_0000` - `0x4000_0FFF`: Baseband Control & Status Register file (`mimo_axi4_lite_slave.v`).
  * `0x4000_1000` - `0x4000_1FFF`: CSI Matrix & Parameter Buffer Memory.
* **Transaction Steering:** Multiplexes read/write valid, ready, data, and response strobes with zero clock latency penalty.
* **Standard-Cell Synthesizable:** Maps directly to combinational multiplexers and logic gates in SCL 180nm.

---

## 4. Hardware Verification & Synthesis Results
* **Formal Verification:** All bus protocols verified against ARM AMBA AXI4-Lite and AXI4-Stream assertion suites.
* **Synthesis:** Fully synthesizable in Cadence Genus against SCL 180nm standard cells with zero multi-cycle path exceptions.
* **Clock Domain:** 100% synchronous to the 100 MHz system clock `clk`.
