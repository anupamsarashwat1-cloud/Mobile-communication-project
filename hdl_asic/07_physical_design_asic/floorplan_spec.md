# SCL 180nm / Cadence 180nm Chip Floorplan & Placement Specification
## Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)

---

## 1. Physical Specifications & Metal Stack

* **Project Identification:** Dedicated Standalone 2x2 MIMO Baseband Processor IC (`SMVDU-MIMO-180`)
* **Target Fabrication Node:** SCL 180nm CMOS Logic Process (Standard SCL 180nm foundry run)
* **Pre-Silicon Virtual Prototyping PDK:** Cadence generic 180nm PDK (`gpdk180` / OSU 180nm standard cell library)
* **Die Size:** $2.0\text{ mm} \times 2.0\text{ mm}$ ($4.0\text{ mm}^2$ total silicon area)
* **Core Cavity Area:** $1.5\text{ mm} \times 1.5\text{ mm}$ ($2.25\text{ mm}^2$)
* **Core Target Utilization:** $65\%$ (guarantees timing closure, low IR drop, and zero congestion)
* **Operating Voltage:**
  * Core Logic: $1.8\text{ V} \pm 10\%$
  * I/O Pad Frame: $3.3\text{ V} \pm 10\%$
* **Metal Interconnect Stack (1P6M - 1 Polysilicon, 6 Metal Layers):**
  * `Metal 1` (M1): Standard cell internal routing and intra-cell connections.
  * `Metal 2 & 3` (M2, M3): Horizontal and vertical signal routing.
  * `Metal 4` (M4): Inter-quadrant datapath buses.
  * `Metal 5 & 6` (M5, M6): Top-level Power Distribution Network (PDN) rings, VDD/VSS mesh stripes, and global clock tree distribution.

---

## 2. Standalone Chip Floorplan & Subsystem Placement

The entire silicon die is dedicated exclusively to the 2x2 MIMO baseband processing engine:

```
+-----------------------------------------------------------------------------------+
|                            NORTH I/O PAD RING (3.3V / 1.8V)                       |
|   [VDD_IO] [RESET_N] [CLK_IN 100MHz] [HOST_CS_N] [HOST_SCLK] [HOST_MOSI] [HOST_MISO]    |
+---+---------------------------------------------------------------------------+---+
|   |  QUADRANT 1: DIGITAL FRONT-END (DFE)     |  QUADRANT 2: TRANSMIT SUBSYSTEM|   |
|   |  - AXI4-Stream I/Q Input FIFO Buffers    |  - Alamouti STBC 2x2 Encoder   |   |
|   |  - I/Q Imbalance & DC Offset Correction  |  - SVD Eigenmode Precoder (V)  |   |
| W |  - Baseband Framing & Packet Sync Engine |  - Water-Filling Power Shaper  | E |
| E |  - Sample Rate Decimation / Interpolation|  - TX Antenna Mapping Multiplexer| A |
| S |------------------------------------------+--------------------------------| S |
| T |             CENTRAL ARBITRATION & CONFIGURATION BUS MATRIX                | T |
|   |         + Mode Control Registers, Status BIST & Power Gating Logic        |   |
| P |------------------------------------------+--------------------------------| P |
| A |  QUADRANT 3: CHANNEL ESTIMATION & FSM    |  QUADRANT 4: ADVANCED RECEIVER | A |
| D |  - 2x2 Channel Matrix H Registers        |  - Alamouti MRC Combining Unit | D |
|   |  - 16-Stage CORDIC SVD Decomposition     |  - Linear MMSE Equalizer Core  |   |
| R |  - Singular Value Pipeline (s1, s2)      |  - Ordered MMSE-SIC Detector   | R |
| I |  - Condition Number (kappa) Comparator   |  - QAM Slicers & Demodulators  | I |
| N |  - Adaptive Rank-Switching FSM Core      |  - Output Stream FIFO & CRC    | N |
| G |                                          |                                | G |
+---+---------------------------------------------------------------------------+---+
|                            SOUTH I/O PAD RING (Baseband I/Q Ports)                |
|   [RX0_I] [RX0_Q] [RX1_I] [RX1_Q] [TX0_I] [TX0_Q] [TX1_I] [TX1_Q] [CORE_VDD]     |
+-----------------------------------------------------------------------------------+
```

---

## 3. Subsystem Placement Rationale

1. **North Periphery (Host Configuration):**
   * Host interface (AXI4-Lite or SPI slave) placed near the North pads to receive run-time parameters (switching thresholds $\kappa_{\text{thresh}} = 4.5$, $\text{SNR}_{\text{thresh}} = 8.0\text{ dB}$, mode override).
2. **South Periphery (RF I/Q Interface):**
   * Placed along the South pad ring directly adjacent to high-speed differential/parallel I/Q pads connecting to an external RF transceiver (e.g. AD9361 / discrete ADC/DAC).
3. **Quadrant 3 & 4 Proximity (Channel Engine to Detectors):**
   * The 16-stage CORDIC SVD engine and channel matrix registers are positioned adjacent to the MMSE-SIC and Alamouti MRC detectors in Quadrant 4 to minimize interconnect delay on the critical path.

---

## 4. Power Distribution Network (PDN) Strategy

* **Power Rings:**
  * Outer Ring: $3.3\text{ V}$ `VDDO` / `VSSO` (Pad ring supply, width = $20\,\mu\text{m}$).
  * Inner Ring: $1.8\text{ V}$ `VDD` / `VSS` (Core supply, width = $15\,\mu\text{m}$).
* **Power Mesh Stripes:**
  * `Metal 6` (Vertical): $1.8\text{ V}$ VDD/VSS stripes, pitch = $40\,\mu\text{m}$, width = $3.5\,\mu\text{m}$.
  * `Metal 5` (Horizontal): $1.8\text{ V}$ VDD/VSS stripes, pitch = $40\,\mu\text{m}$, width = $3.5\,\mu\text{m}$.
  * Dynamic IR Drop Target: $< 5\%$ ($< 90\text{ mV}$) across all simultaneous switching vectors.
