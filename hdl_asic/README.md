# Standalone 2x2 MIMO Baseband Processor ASIC (SMVDU-MIMO-180)
## Complete Synthesizable Verilog RTL Generated via MathWorks MATLAB HDL Coder

---

## 1. Project Overview & ASIC Scope
This directory contains the complete, production-grade Hardware Description Language (HDL) architecture for the **Standalone 2x2 MIMO Baseband Processor ASIC (`SMVDU-MIMO-180`)**.

* **Course & Institution:** B.Tech Capstone Project (ECL DC 401 Mobile Communication) | Shri Mata Vaishno Devi University (SMVDU)
* **Team:** Anupam Sarashwat, Harsh Mishra, Om Kumar, Ashmit Raj
* **HDL Generation Methodology:** **100% Programmatically Generated via MathWorks MATLAB HDL Coder** from verified, bit-accurate MATLAB hardware kernels.
* **Target Fabrication Node:** SCL 180nm CMOS (1P6M) with Cadence generic 180nm PDK (`gpdk180`) pre-silicon virtual prototyping.

---

## 2. Repository Directory Structure & Parallel Documentation

Each subsystem is organized with its HDL Coder generated synthesizable Verilog modules and a dedicated parallel `README.md` detailing its mathematical mapping, microarchitecture, clock latency, and pinout:

```
hdl_asic/
├── README.md                                  # Top-Level ASIC Baseband Architecture Guide
├── FUNCTIONAL_BLOCK_DIAGRAM.md                # Complete Chip Functional Datapath Diagram
├── build_rtl/                                 # Consolidated Synthesizable Verilog (.v) Library
│   ├── adaptive_controller_hw.v
│   ├── alamouti_combiner_hw.v
│   ├── alamouti_encoder_hw.v
│   ├── mmse_sic_hw.v
│   ├── qam_slicer_hw.v
│   ├── water_filling_hw.v
│   └── (Native Floating Point Math Cores: nfp_add, nfp_div, nfp_mul, etc.)
├── 01_interfaces_and_bus/                     # Standard AXI4-Lite & AXI4-Stream Interface Specs
│   ├── README.md                              # Register memory map & timing diagrams
│   ├── mimo_axi4_lite_slave.v
│   └── mimo_axis_stream_adapter.v
├── 02_alamouti_stbc/                          # STBC 2x2 Transmit & Receive Diversity Engine
│   ├── README.md                              # Datapath microarchitecture, d=4, latency specs
│   ├── alamouti_encoder_hw.v
│   ├── alamouti_combiner_hw.v
│   └── (Math Cores: nfp_mul, nfp_add, nfp_div, nfp_sub, nfp_uminus)
├── 03_svd_and_waterfilling/                   # Pipelined Water-Filling Power Allocator
│   ├── README.md                              # Unrolled 2-stage comparator & power budget specs
│   ├── water_filling_hw.v
│   └── (Math Cores: nfp_add, nfp_div, nfp_sub, nfp_relop)
├── 04_adaptive_controller/                    # Real-Time Dynamic Rank Adaptation Controller
│   ├── README.md                              # Cross-multiplication comparator & FSM specs
│   ├── adaptive_controller_hw.v
│   └── (Math Cores: nfp_mul, nfp_relop)
├── 05_mmse_sic_receiver/                      # Ordered MMSE-SIC Detection Core & Slicers
│   ├── README.md                              # Non-linear V-BLAST cancellation & QAM slicing
│   ├── mmse_sic_hw.v
│   ├── qam_slicer_hw.v
│   └── (Math Cores: nfp_div, nfp_recip, nfp_mul, nfp_add, nfp_sub)
└── 07_physical_design_asic/                   # ASIC Physical Design & Cadence Toolchain
    ├── README.md                              # SCL 180nm / Cadence 180nm P&R Guide
    ├── ASIC_PHYSICAL_DESIGN_SYNTHESIS_GUIDE.md # 10-page Synthesis, STA, DRC/LVS Manual
    ├── floorplan_spec.md                      # 2x2mm Standalone Die Floorplan & Pad Ring
    ├── constraints.sdc                        # 100 MHz Production SDC Constraints
    ├── sdc/mimo_baseband_100mhz.sdc
    └── scripts/                               # Executable Cadence EDA Scripts
        ├── run_genus_synth.tcl                # Cadence Genus Logic Synthesis
        ├── run_conformal_lec.do               # Cadence Conformal Formal Verification
        ├── viewDefinition.tcl                 # MMMC Multi-Corner PVT Definitions
        ├── run_innovus_pnr.tcl                # Cadence Innovus Place & Route
        ├── run_tempus_sta.tcl                 # Cadence Tempus Signoff Static Timing Analysis
        └── run_pegasus_pv.tcl                 # Cadence Pegasus DRC / LVS Physical Verification
```

---

## 3. MATLAB HDL Coder Synthesis Summary

| Hardware Kernel | Source `.m` Function | Generated Verilog Top-Level | Pipeline Latency | HDL Conformance |
|---|---|---|:---:|:---:|
| **STBC 2x2 Encoder** | [alamouti_encoder_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/alamouti_encoder_hw.m) | `alamouti_encoder_hw.v` | 10 cycles | **0 Errors, 0 Warnings** |
| **STBC 2x2 MRC Combiner** | [alamouti_combiner_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/alamouti_combiner_hw.m) | `alamouti_combiner_hw.v` | 122 cycles | **0 Errors, 0 Warnings** |
| **Water-Filling Power Allocator** | [water_filling_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/water_filling_hw.m) | `water_filling_hw.v` | 75 cycles | **0 Errors, 0 Warnings** |
| **Dynamic Rank Controller** | [adaptive_controller_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/adaptive_controller_hw.m) | `adaptive_controller_hw.v` | 12 cycles | **0 Errors, 0 Warnings** |
| **Hard Decision QAM Slicer** | [qam_slicer_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/qam_slicer_hw.m) | `qam_slicer_hw.v` | 5 cycles | **0 Errors, 0 Warnings** |
| **Ordered MMSE-SIC Detector** | [mmse_sic_hw.m](file:///c:/Users/anupa/OneDrive/Documents/Mobile%20Communication%20Project/hdl_src_matlab/mmse_sic_hw.m) | `mmse_sic_hw.v` | 291 cycles | **0 Errors, 0 Warnings** |

---

## 4. How to Re-Run HDL Synthesis via Terminal
To reproduce or re-run the automated MATLAB HDL Coder synthesis from the command line:

```powershell
& "C:\Program Files\MATLAB\R2026b\bin\matlab.exe" -batch "generate_hdl_coder_all"
```
Or use the launcher:
```powershell
.\run_hdl_coder.bat
```
