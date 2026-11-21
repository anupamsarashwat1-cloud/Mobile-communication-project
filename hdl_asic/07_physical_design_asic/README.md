# ASIC Physical Design & Cadence Toolchain Automation
## 2x2 MIMO Baseband Processor (SCL 180nm / Cadence gpdk180 Flow)

This directory contains the production-grade SDC timing constraints, MMMC view definitions, and executable Cadence TCL/dofile scripts for synthesizing, formally verifying, placing, routing, and signing off the **2x2 MIMO Baseband Processor**.

---

## Directory Contents

- **`ASIC_PHYSICAL_DESIGN_SYNTHESIS_GUIDE.md`**: Master physical design and synthesis technical report detailing toolchain flow, SCL 180nm porting strategy, pad ring integration, and signoff criteria.
- **`sdc/`**:
  - `mimo_baseband_100mhz.sdc`: Target 100 MHz clock constraints with 20% setup margin (2.0ns), 200ps jitter, and I/O budgets.
- **`scripts/`**:
  - `run_genus_synth.tcl`: Logic synthesis and PLE mapping via Cadence Genus.
  - `run_conformal_lec.do`: Formal Boolean equivalence proof via Cadence Conformal LEC.
  - `viewDefinition.tcl`: Multi-Mode Multi-Corner (MMMC) definition file for Innovus.
  - `run_innovus_pnr.tcl`: Floorplanning, PDN, placement, CCOpt CTS, and NanoRouting via Cadence Innovus.
  - `run_tempus_sta.tcl`: Signoff Static Timing Analysis via Cadence Tempus.
  - `run_pegasus_pv.tcl`: DRC, LVS, and Antenna verification via Cadence Pegasus / PVS.
- **`reports/`**: Destination directory for all auto-generated timing, area, power, and verification reports.
- **`outputs/`**: Final synthesized gate-level netlists, GDSII, DEF, and extracted SPEF files.

---

## Quickstart Tool Commands

### 1. Logic Synthesis (Cadence Genus)
```bash
genus -f scripts/run_genus_synth.tcl -log reports/genus/genus.log
```

### 2. Logic Equivalence Checking (Cadence Conformal LEC)
```bash
lec -xl -nogui -dofile scripts/run_conformal_lec.do
```

### 3. Physical Place & Route (Cadence Innovus)
```bash
innovus -files scripts/run_innovus_pnr.tcl -log reports/innovus/innovus.log
```

### 4. Signoff Static Timing Analysis (Cadence Tempus)
```bash
tempus -files scripts/run_tempus_sta.tcl -log reports/tempus/tempus.log
```

### 5. Physical DRC/LVS Verification (Cadence Pegasus)
```bash
genus -f scripts/run_pegasus_pv.tcl
```
