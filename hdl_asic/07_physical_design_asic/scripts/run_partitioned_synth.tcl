# ==============================================================================
# Cadence Genus Partitioned / Hierarchical Synthesis Script
# Design: SMVDU-MIMO-180 Standalone 2x2 MIMO Baseband Processor
# Target Technology: SCL 180nm CMOS / Cadence gpdk180 1P6M
# Mode: Partition-Preserving & Modular Subsystem Synthesis
# ==============================================================================
# Description:
#   Implements hierarchical, partition-preserving synthesis for the 2x2 MIMO
#   ASIC. Enforces strict module boundary preservation across the 5 functional
#   subsystems (01_interfaces_and_bus, 02_alamouti_stbc, 03_svd_and_waterfilling,
#   04_adaptive_controller, 05_mmse_sic_receiver), matching the 4-quadrant
#   physical floorplan specified in floorplan_spec.md.
#
#   Supports two operational modes:
#     - MODE 1: Top-Down Hierarchical Synthesis with Preserved Subsystem Fences
#     - MODE 2: Bottom-Up Out-of-Context (OOC) Sub-Block Characterization
# ==============================================================================

set SCRIPT_DIR [file dirname [info script]]
set ASIC_ROOT  [file normalize "${SCRIPT_DIR}/../.."]

# Directory Configurations
set REPORT_DIR "${SCRIPT_DIR}/../reports/partitioned_synth"
set OUTPUT_DIR "${SCRIPT_DIR}/../outputs/partitioned_synth"
file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR

# PDK Library Configurations
set LIB_DIR "/cadence/pdk/gpdk180/lib" ; # Modify per foundry/lab path
set LEF_DIR "/cadence/pdk/gpdk180/lef"

set_db / .target_library [list "${LIB_DIR}/slow_vdd1v8_125c.lib"]
set_db / .link_library   [list "*" "${LIB_DIR}/slow_vdd1v8_125c.lib" "${LIB_DIR}/fast_vdd1v8_m40c.lib"]
set_db / .lef_library    [list "${LEF_DIR}/gpdk180_tech.lef" "${LEF_DIR}/gpdk180_stdcells.lef"]

set_db / .init_ground_nets {VSS GND}
set_db / .init_power_nets  {VDD}
set_multi_cpu_usage -local_cpu 8

puts "======================================================================"
puts " STEP 1: LOAD RTL WITH EXPLICIT SUBSYSTEM PARTITIONING                "
puts "======================================================================"

# Subsystem 00: IEEE-754 Single Native Floating Point (NFP) Library
set NFP_RTL [list \
    "${ASIC_ROOT}/build_rtl/nfp_uminus_single.v" \
    "${ASIC_ROOT}/build_rtl/nfp_gain_pow2_single.v" \
    "${ASIC_ROOT}/build_rtl/nfp_relop_single.v" \
    "${ASIC_ROOT}/build_rtl/nfp_relop_single_block.v" \
    "${ASIC_ROOT}/build_rtl/nfp_relop_single_block1.v" \
    "${ASIC_ROOT}/build_rtl/nfp_relop_single_block2.v" \
    "${ASIC_ROOT}/build_rtl/nfp_add_single.v" \
    "${ASIC_ROOT}/build_rtl/nfp_sub_single.v" \
    "${ASIC_ROOT}/build_rtl/nfp_mul_single.v" \
    "${ASIC_ROOT}/build_rtl/nfp_div_single.v" \
    "${ASIC_ROOT}/build_rtl/nfp_recip_single.v" \
]

# Subsystem 01: Host Bus Interfaces & Crossbar (Quadrant 1)
set BUS_RTL [list \
    "${ASIC_ROOT}/01_interfaces_and_bus/mimo_axi4_lite_slave.v" \
    "${ASIC_ROOT}/01_interfaces_and_bus/mimo_axis_stream_adapter.v" \
    "${ASIC_ROOT}/01_interfaces_and_bus/mimo_interconnect_crossbar.v" \
]

# Subsystem 02: Alamouti STBC Transceiver Core (Quadrant 2 & 4)
set STBC_RTL [list \
    "${ASIC_ROOT}/build_rtl/alamouti_encoder_hw.v" \
    "${ASIC_ROOT}/build_rtl/alamouti_combiner_hw.v" \
]

# Subsystem 03: Water-Filling Power Allocator (Quadrant 2)
set WF_RTL [list \
    "${ASIC_ROOT}/build_rtl/water_filling_hw.v" \
]

# Subsystem 04: Real-Time Dynamic Mode & Rank Controller (Quadrant 3)
set CTRL_RTL [list \
    "${ASIC_ROOT}/build_rtl/adaptive_controller_hw.v" \
]

# Subsystem 05: Non-Linear Ordered MMSE-SIC Receiver & Slicers (Quadrant 4)
set SIC_RTL [list \
    "${ASIC_ROOT}/build_rtl/mmse_sic_hw.v" \
    "${ASIC_ROOT}/build_rtl/qam_slicer_hw.v" \
]

# Top-Level Structural ASIC Wrapper
set TOP_RTL [list \
    "${ASIC_ROOT}/06_top_integration/mimo_baseband_top.v" \
]

# Read all partition sources
foreach f [concat $NFP_RTL $BUS_RTL $STBC_RTL $WF_RTL $CTRL_RTL $SIC_RTL $TOP_RTL] {
    read_hdl -language v2001 $f
}

puts "======================================================================"
puts " STEP 2: ELABORATE & ENFORCE BOUNDARY PRESERVATION ON ALL PARTITIONS  "
puts "======================================================================"

elaborate mimo_baseband_top
current_design mimo_baseband_top

# ------------------------------------------------------------------------------
# Enforce Hierarchical Partitioning (Prevent Boundary Flattening)
# ------------------------------------------------------------------------------
# 1. Disable global auto-ungrouping to keep the modular subsystem hierarchy
set_db / .auto_ungroup none

# 2. Preserve specific partition instances as distinct hierarchical blocks
# These instances correspond directly to the 4 Quadrants in the physical floorplan:
# Quadrant 1: AXI4-Lite & Streaming Bus Interface
set_db [get_cells -hierarchical *u_interconnect*]       .ungroup_ok false
set_db [get_cells -hierarchical *u_axi*]               .ungroup_ok false

# Quadrant 2: Transmit STBC Encoder & Water-Filling Power Allocator
set_db [get_cells -hierarchical *u_alamouti_encoder*]  .ungroup_ok false
set_db [get_cells -hierarchical *u_water_filling*]     .ungroup_ok false
set_db [get_cells -hierarchical *u_sq1*]               .ungroup_ok false
set_db [get_cells -hierarchical *u_sq2*]               .ungroup_ok false

# Quadrant 3: Cognitive Channel Estimator & Dynamic Rank Controller
set_db [get_cells -hierarchical *u_adaptive_controller*] .ungroup_ok false

# Quadrant 4: High-Performance MMSE-SIC Detection & Slicers (Critical Timing Path)
set_db [get_cells -hierarchical *u_alamouti_combiner*] .ungroup_ok false
set_db [get_cells -hierarchical *u_mmse_sic*]          .ungroup_ok false
set_db [get_cells -hierarchical *u_slicer_stream1*]    .ungroup_ok false
set_db [get_cells -hierarchical *u_slicer_stream2*]    .ungroup_ok false

puts "======================================================================"
puts " STEP 3: APPLY TIMING CONSTRAINTS & PARTITIONED SDC BUDGETING         "
puts "======================================================================"

read_sdc "${SCRIPT_DIR}/../sdc/mimo_baseband_100mhz.sdc"

# Set specialized synthesis effort on timing-critical datapath partitions
# Quadrant 4 (MMSE-SIC Gram matrix inversion & feedback cancellation) contains
# the deepest logic depth; enforce high datapath optimization effort:
set_db [get_cells -hierarchical *u_mmse_sic*] .dp_effort high
set_db [get_cells -hierarchical *u_alamouti_combiner*] .dp_effort high

puts "======================================================================"
puts " STEP 4: HIERARCHICAL SYNTHESIS EXECUTION (GENERIC -> MAP -> OPT)     "
puts "======================================================================"

set_db / .syn_generic_effort high
set_db / .syn_map_effort     high
set_db / .syn_opt_effort     high

puts "--- Synthesizing Partitioned Architecture ---"
syn_generic
syn_map
syn_opt

puts "======================================================================"
puts " STEP 5: PER-PARTITION HIERARCHICAL QOR REPORTING                     "
puts "======================================================================"

# Subsystem Area Breakdown
report_area -detail > ${REPORT_DIR}/subsystems_area_breakdown.rpt

# Subsystem Timing Slack per Partition
report_timing -from [get_cells -hierarchical *u_alamouti_encoder*]   -max_paths 10 > ${REPORT_DIR}/quad2_tx_timing.rpt
report_timing -from [get_cells -hierarchical *u_adaptive_controller*]-max_paths 10 > ${REPORT_DIR}/quad3_ctrl_timing.rpt
report_timing -from [get_cells -hierarchical *u_mmse_sic*]          -max_paths 20 > ${REPORT_DIR}/quad4_sic_timing.rpt
report_timing -from [get_cells -hierarchical *u_alamouti_combiner*] -max_paths 20 > ${REPORT_DIR}/quad4_stbc_timing.rpt

# Subsystem Power Hierarchy
report_power -hierarchy > ${REPORT_DIR}/subsystems_power_hierarchy.rpt
report_qor              > ${REPORT_DIR}/overall_qor_summary.rpt

puts "======================================================================"
puts " STEP 6: EXPORT NETLIST WITH HIERARCHICAL PARTITIONS INTACT           "
puts "======================================================================"

# Netlist with preserved module ports for Innovus physical quadrant placement
write_hdl -mapped > ${OUTPUT_DIR}/mimo_baseband_partitioned_synth.v
write_sdc         > ${OUTPUT_DIR}/mimo_baseband_partitioned_synth.sdc

puts "Partitioned synthesis completed successfully. Subsystems ready for Innovus physical quadrant placement."
