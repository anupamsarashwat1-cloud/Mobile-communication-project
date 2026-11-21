# SCL 180nm / Cadence 180nm Chip Floorplan & Placement Specification
## SMVDU-TITAN-X Heterogeneous SoC with Integrated MIMO Baseband Accelerator

---

## 1. Physical Specifications & Metal Stack

* **Target Fabrication Node:** SCL 180nm CMOS Logic Process (Standard SCL 180nm foundry run)
* **Pre-Silicon Verification & Synthesis PDK:** Cadence generic 180nm PDK (`gpdk180` / OSU 180nm standard cell library)
* **Die Size:** $5.0\text{ mm} \times 5.0\text{ mm}$ ($25.0\text{ mm}^2$ total silicon area)
* **Core Cavity Area:** $4.2\text{ mm} \times 4.2\text{ mm}$ ($17.64\text{ mm}^2$)
* **Core Target Utilization:** $65\%$ (guarantees timing closure without wire congestion)
* **Operating Voltage:**
  * Core Logic: $1.8\text{ V} \pm 10\%$
  * I/O Ring: $3.3\text{ V} \pm 10\%$
* **Metal Interconnect Stack (1P6M - 1 Polysilicon, 6 Metal Layers):**
  * `Metal 1` (M1): Standard cell internal routing and intra-cell connections.
  * `Metal 2 & 3` (M2, M3): Horizontal and vertical signal routing.
  * `Metal 4` (M4): High-speed bus routing (AXI4 Crossbar matrix).
  * `Metal 5 & 6` (M5, M6): Top-level Power Distribution Network (PDN) rings, VDD/VSS mesh stripes, and global clock tree distribution.

---

## 2. Chip Floorplan & Quadrant Placement Map

```
+-----------------------------------------------------------------------------------+
|                            NORTH I/O PAD RING (3.3V)                              |
|   [GPIO] [JTAG_TCK] [JTAG_TMS] [JTAG_TDI] [JTAG_TDO] [RESET_N] [CLK_IN 100MHz]    |
+---+---------------------------------------------------------------------------+---+
|   |  QUADRANT 1: COMPUTE COMPLEX             |  QUADRANT 2: MEMORY HIERARCHY  |   |
|   |  - Core 0: RV64GC (32KB L1 I/D)          |  - 512KB Unified 4-Way L2      |   |
|   |  - Core 1: RV64GC (32KB L1 I/D)          |    SRAM Cache (Banked Macros)  |   |
|   |  - Core 2: RV64GC (32KB L1 I/D)          |  - Boot ROM & OTP Security     |   |
| W |  - Core 3: RV64GC (32KB L1 I/D)          |  - Memory BIST Controllers     | E |
| E |  - Core 4: RV64IMAC (Monitor Hart)       |                                | A |
| S |------------------------------------------+--------------------------------| S |
| T |             CENTER: 15-MASTER x 9-SLAVE AXI4 CROSSBAR MATRIX              | T |
|   |         + PLIC Interrupt Controller & Power Management Unit (PMU)         |   |
| P |------------------------------------------+--------------------------------| P |
| A |  QUADRANT 3: SYSTEM PERIPHERALS          |  QUADRANT 4: 2x2 MIMO BASEBAND | A |
| D |  - UART0 / UART1, SPI0 / SPI1            |              ACCELERATOR       | D |
|   |  - I2C, Timers, Watchdog                 |  - SVD CORDIC Systolic Array   |   |
| R |  - DMA Engine & High-Speed Link          |  - MMSE-SIC Detection Engine   | R |
| I |  - Crypto Enclave (AES/SHA/ECC)          |  - Alamouti STBC Core          | I |
| N |                                          |  - Water-Filling & Mode FSM    | N |
| G |                                          |  - AXI4-Stream Baseband DMA    | G |
+---+---------------------------------------------------------------------------+---+
|                            SOUTH I/O PAD RING (3.3V / 1.8V)                       |
|   [I_RX0] [Q_RX0] [I_RX1] [Q_RX1] [I_TX0] [Q_TX0] [I_TX1] [Q_TX1] [CORE_VDD]     |
+-----------------------------------------------------------------------------------+
```

---

## 3. Quadrant 4: MIMO Baseband Accelerator Floorplan

Within Quadrant 4, sub-modules are placed to minimize latency and critical path lengths:

1. **North Edge of Quadrant 4:**
   * `mimo_axi4_lite_slave.v`: Placed directly bordering the central AXI4 crossbar to receive memory-mapped control words (SNR, condition number thresholds, mode overrides).
2. **West Edge of Quadrant 4:**
   * `mimo_axis_stream_adapter.v`: Interfaced to the system DMA controller to ingest incoming I/Q samples and stream detected symbols.
3. **Core Datapath Cluster (Center & East):**
   * `svd_cordic_engine.v` (16 pipeline stages) placed directly adjacent to `water_filling_allocator.v` to ensure single-cycle singular value transfer ($\sigma_1, \sigma_2$).
   * `mmse_sic_core.v` placed adjacent to the QAM constellation slicer macros to eliminate wire delays during cancellation feedback.
   * `alamouti_combiner.v` placed near the stream output multiplexer.

---

## 4. Power Distribution Network (PDN) Strategy

* **Power Rings:**
  * Outer Ring: $3.3\text{ V}$ `VDDO` / `VSSO` (Pad ring supply, width = $25\,\mu\text{m}$).
  * Inner Ring: $1.8\text{ V}$ `VDD` / `VSS` (Core supply, width = $20\,\mu\text{m}$).
* **Power Mesh Stripes:**
  * `Metal 6` (Vertical): $1.8\text{ V}$ VDD/VSS stripes, pitch = $50\,\mu\text{m}$, width = $4\,\mu\text{m}$.
  * `Metal 5` (Horizontal): $1.8\text{ V}$ VDD/VSS stripes, pitch = $50\,\mu\text{m}$, width = $4\,\mu\text{m}$.
  * IR Drop Target: $< 5\%$ ($< 90\text{ mV}$ drop across highest switching activity).
