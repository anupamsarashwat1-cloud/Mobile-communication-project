# Tri-Framework Master Implementation Plan: MATLAB to ASIC Conversion
## Mobile Communication MIMO Baseband Processor (SMVDU Capstone & TITAN-X Accelerator)

---

## 1. Executive Framework Architecture

This implementation plan orchestrates three autonomous engineering frameworks:
1. **GSD (Get Shit Done)**: Macro-lifecycle management (5-phase Spec-Driven Development: Discuss → Plan → Execute → Verify → Ship) and persistent state tracking in `.planning/`.
2. **Roo Code (Multi-Mode Cognitive Discipline)**: Role-specialized development modes (Architect, Code, Debug, Ask) ensuring clean architectural contracts, surgical code refactoring, and scientific verification.
3. **Ralph Loop (Autonomous Execution & Agent Backpressure)**: Iterative, disk-backed task execution running against `prd.json` with strict testbench/linter backpressure until all verification gates pass (`<promise>COMPLETE</promise>`).

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        MACRO-LIFECYCLE: GSD SPEC-DRIVEN PHASES                         │
│  Phase 1: Specs & Arch  ──►  Phase 2: Restructure  ──►  Phase 3: HDL Coder  ──► Phase 4: ASIC │
│  (.planning/STATE.md)        (Fixed-Point fi)           (Verilog Generation)    (Synthesis)    │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                     MICRO-TASK EXECUTION ENGINE: THE RALPH LOOP                        │
│                                                                                        │
│     ┌─────────────────┐         ┌─────────────────┐         ┌──────────────────┐       │
│     │  Read prd.json  │  ────►  │ Select Story ID │  ────►  │   Execute via    │       │
│     │ & progress.txt  │         │ (e.g. STBC-01)  │         │   Roo Code Mode  │       │
│     └─────────────────┘         └─────────────────┘         └────────┬─────────┘       │
│              ▲                                                       │                 │
│              │                   ┌──────────────────┐                ▼                 │
│              │                   │ Git Commit State │         ┌──────────────────┐     │
│              └────────────────── │ & Update prd.json│  ◄────  │ Agent Backpressure│     │
│                                  └──────────────────┘         │ (HDL / ModelSim) │     │
│                                                               └──────────────────┘     │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Tri-Framework Role Matrix

| Development Stage | GSD Phase | Roo Code Persona | Ralph Loop Story Focus | Agent Backpressure Tool |
|---|---|---|---|---|
| **System Partitioning & Interface Specification** | Phase 1: DISCUSS & PLAN | **Architect Mode** | `ARCH-01`: Top-level AXI4-Stream & AXI4-Lite port definitions | Interface linting & MATLAB typecheck |
| **Fixed-Point Quantization & Refactoring** | Phase 2: EXECUTE | **Code Mode** | `FXP-01` to `FXP-05`: Convert algorithms to static-size `fi` objects | SQNR $> 40\text{ dB}$, BER gap $< 0.1\text{ dB}$ |
| **HDL Coder Scripting & RTL Generation** | Phase 3: EXECUTE | **Code Mode** | `HDL-01` to `HDL-04`: Generate modular Verilog via `coder.config('hdl')` | HDL Coder compilation & clean linting |
| **Functional & Cycle-Accurate Verification** | Phase 4: VERIFY | **Debug Mode** | `VERIF-01`: Bit-accurate testbench cosimulation | Zero mismatch against MATLAB golden vector |
| **ASIC Synthesis & STA Signoff** | Phase 5: SHIP | **Architect Mode** | `ASIC-01`: SDC timing constraints, area, and power closure | SCL 180nm / Yosys / OpenLane / Synopsys DC |

---

## 3. Four-Phase Conversion Roadmap

### Phase 1: Architectural Definition & Bus Contracts (Roo Architect)
* **Goal**: Establish the structural boundary of the hardware accelerator.
* **Deliverables**:
  1. Top-level wrapper interface: `mimo_baseband_top.v`
  2. Data plane: Dual 16-bit complex AXI4-Stream (`s_axis_iq_tdata`, `m_axis_demod_tdata`)
  3. Control plane: 32-bit AXI4-Lite slave with register map:
     - `0x00`: Control Register (`start`, `reset_core`, `mode_override_en`, `manual_mode_sel`)
     - `0x04`: Status Register (`active_mode`, `kappa_overflow`, `core_idle`)
     - `0x08`: Condition Number Threshold $\kappa_{\text{thresh}}$ (Default: $4.5$ in Q8.8 format = `0x0480`)
     - `0x0C`: SNR Switching Threshold $\gamma_{\text{thresh}}$ (Default: $8.0\text{ dB}$ in Q8.8 = `0x0800`)
     - `0x10`: Total Transmit Power Budget $P_{\text{total}}$

### Phase 2: Algorithmic Refactoring for Static Synthesis (Roo Code + Ralph Loop)
* **Goal**: Restructure MATLAB source into deterministic, hardware-synthesizable kernels.
* **Stories in `prd.json`**:
  * `MOD-01 (Alamouti STBC)`: Refactor `alamouti_stbc_2x2.m` into a streaming state machine with fixed arrays and 16-bit Q1.15 I/Q registers.
  * `MOD-02 (Water-Filling)`: Replace unbounded `while` loop in `water_filling_algorithm.m` with an unrolled 2-stage comparator pipeline:
    $$\mu = \frac{P_{\text{tot}} + \sigma_n^2/\sigma_1^2 + \sigma_n^2/\sigma_2^2}{2}$$
    Clamp negative allocation in single clock cycle.
  * `MOD-03 (SVD Decoupling)`: Replace `svd(H)` with a 16-stage 2D CORDIC Givens rotation array.
  * `MOD-04 (Adaptive Controller)`: Replace division in $\kappa = \sigma_1/\sigma_2$ with cross-multiplication: $\sigma_1 > 4.5 \cdot \sigma_2$.
  * `MOD-05 (MMSE-SIC)`: Pipeline Cholesky decomposition and symbol feedback slicers.

### Phase 3: Automated HDL Coder Synthesis (Roo Code)
* **Goal**: Execute MATLAB HDL Coder to generate ASIC-grade Verilog.
* **HDL Coder Parameters**:
  * Target: Standard IEEE 1364-2001 Verilog (Zero vendor primitives).
  * Reset: Synchronous active-high (`rst`) or asynchronous active-low with internal synchronizer (`rst_n`).
  * Pipeline Retiming: `DistributedPipelining = true`, `AdaptivePipelining = true`.
  * RAM / Multipliers: Generic gate/DFF inference for ASIC standard cell mapping.

### Phase 4: Functional Verification & ASIC Hand-Off (Roo Debug)
* **Goal**: Verify cycle-accurate equivalence and synthesize to gate-level netlist.
* **Verification Gates**:
  1. Automated testbench execution (`mimo_baseband_top_tb.v`).
  2. Cosimulation via MATLAB HDL Verifier with 10,000 Monte Carlo channel realizations.
  3. Static Timing Analysis (STA) at target clock (100 MHz on SCL 180nm, 250 MHz on TSMC 28nm).
  4. Integration into the SMVDU-TITAN-X RISC-V SoC crossbar.

---

## 4. Git Branching Strategy & Modular HDL Directory Structure

To keep the `main` branch pristine with the original MATLAB baseline, all physical design and HDL engineering is developed on the dedicated branch:
* **Active Working Branch:** `feature/asic-hdl-design`

### Target Repository Layout (with Parallel READMEs)
```
hdl_asic/
├── README.md                                  # Master ASIC & Baseband Architecture Guide
├── 01_interfaces_and_bus/                     # AXI4-Lite & AXI4-Stream wrappers
│   ├── README.md                              # Register map & timing diagrams
│   ├── mimo_axi4_lite_slave.v
│   └── mimo_axis_stream_adapter.v
├── 02_alamouti_stbc/                          # STBC 2x2 Transmit & Receive Core
│   ├── README.md                              # Datapath microarchitecture & latency
│   ├── alamouti_encoder.v
│   ├── alamouti_combiner.v
│   └── tb_alamouti.v
├── 03_svd_and_waterfilling/                   # SVD CORDIC engine & Power Allocator
│   ├── README.md                              # Givens rotation CORDIC & WF pipeline specs
│   ├── cordic_2x2_svd.v
│   ├── water_filling_allocator.v
│   └── tb_svd_wf.v
├── 04_adaptive_controller/                    # Real-time rank & mode selection FSM
│   ├── README.md                              # Cross-multiplication comparator & FSM states
│   ├── adaptive_mode_fsm.v
│   └── tb_adaptive_controller.v
├── 05_mmse_sic_receiver/                      # V-BLAST Non-linear Detection
│   ├── README.md                              # Cancellation feedback pipeline & slicers
│   ├── mmse_sic_core.v
│   ├── qam_slicer.v
│   └── tb_mmse_sic.v
├── 06_top_integration/                        # Top-level DUT + Self-checking testbench
│   ├── README.md                              # Full chip integration & verification guide
│   ├── mimo_baseband_top.v
│   └── mimo_baseband_top_tb.v
└── 07_physical_design_asic/                   # ASIC Constraints & Synthesis
    ├── README.md                              # SDC, multi-VT standard cells & STA closure
    ├── constraints.sdc
    ├── run_synthesis.tcl
    └── cell_library_mapping.md
```

Each subdirectory contains a **dedicated parallel `README.md`** covering:
1. **Mathematical-to-Hardware Equivalence:** Equations mapped to RTL operations.
2. **Microarchitectural Block Diagrams:** Registers, multiplexers, and pipeline stages.
3. **Signal & Pin Interface Specifications:** Signal names, bit-widths, direction, and valid/ready handshakes.
4. **Latency & Throughput:** Exact clock cycles from input valid to output ready.
5. **Self-Checking Testbench Instructions:** Test vectors and assertion metrics.

---

## 5. Ralph Loop Task Specification (`prd.json`)

```json
{
  "project": "MIMO-Baseband-ASIC-Conversion",
  "branchName": "feature/hdl-coder-asic-pipeline",
  "version": "1.0.0",
  "stories": [
    {
      "id": "ARCH-01",
      "title": "Define Top-Level AXI4-Stream & AXI4-Lite Hardware Interfaces",
      "mode": "roo:architect",
      "acceptanceCriteria": [
        "Interface specification documented with exact bitwidths",
        "AXI4-Lite register memory map finalized",
        "MATLAB wrapper function signatures match hardware ports"
      ],
      "passes": false
    },
    {
      "id": "FXP-01",
      "title": "Fixed-Point Quantization of Alamouti STBC Encoder and Combiner",
      "mode": "roo:code",
      "acceptanceCriteria": [
        "All variables cast to fi(..., 1, 16, 15)",
        "SQNR exceeds 40 dB compared to double precision",
        "BER curve shows < 0.1 dB implementation loss"
      ],
      "passes": false
    },
    {
      "id": "FXP-02",
      "title": "Unrolled Fixed-Point Water-Filling Engine",
      "mode": "roo:code",
      "acceptanceCriteria": [
        "No dynamic while loops or vector sizing",
        "Fixed 2-stage pipelined allocation logic",
        "Allocated power matches theoretical water-filling within 0.5%"
      ],
      "passes": false
    },
    {
      "id": "FXP-03",
      "title": "CORDIC-Based 2x2 SVD Decoupling Engine",
      "mode": "roo:code",
      "acceptanceCriteria": [
        "Replaces svd() with iterative Givens rotations",
        "Orthogonality metric ||U*U^H - I|| < 1e-3 in fixed point",
        "Execution latency fixed at 16 cycles"
      ],
      "passes": false
    },
    {
      "id": "HDL-01",
      "title": "Configure and Execute MATLAB HDL Coder Script",
      "mode": "roo:code",
      "acceptanceCriteria": [
        "coder.config('hdl') script configured with ASIC constraints",
        "Synthesizable Verilog emitted to build/asic_rtl/",
        "Zero vendor-specific primitives generated"
      ],
      "passes": false
    },
    {
      "id": "VERIF-01",
      "title": "Bit-Accurate Functional Verification via HDL Verifier",
      "mode": "roo:debug",
      "acceptanceCriteria": [
        "Self-checking testbench compiles in simulator (XSIM/ModelSim/Verilator)",
        "Zero mismatches across 10,000 randomized symbols",
        "Functional coverage achieves 100% across STBC and SM modes"
      ],
      "passes": false
    },
    {
      "id": "ASIC-01",
      "title": "ASIC Logic Synthesis & Timing Closure",
      "mode": "roo:architect",
      "acceptanceCriteria": [
        "SDC timing constraint file generated (100 MHz target)",
        "Logic synthesis passes with 0 setup/hold violations",
        "Standard-cell gate count and power estimation logged"
      ],
      "passes": false
    }
  ]
}
```

---

## 5. Execution Protocol

To execute this plan:
1. **Initialize State**: Create `.planning/` directory containing this roadmap and initialize `prd.json` and `progress.txt`.
2. **Launch Iterations**: Pick the first unpassed story (`ARCH-01`), activate the assigned Roo Code mode, implement the modifications, and run test verification.
3. **Commit & Iterate**: Commit passing code with atomic git messages, update `prd.json`, and continue the loop until the final story (`ASIC-01`) passes.
