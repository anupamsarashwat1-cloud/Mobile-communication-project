// ==============================================================================
// Cadence Conformal Logic Equivalence Checking (LEC) Script
// Golden: Synthesizable RTL from HDL Coder
// Revised: Gate-Level Netlist from Genus Synthesis
// Technology: 180nm Standard Cell Library
// ==============================================================================

// Set log and diagnostic environment
set log file ../reports/lec/conformal_lec.log -replace
set undefined cell black_box -both

// ------------------------------------------------------------------------------
// 1. SETUP MODE: Read Golden Design (RTL)
// ------------------------------------------------------------------------------
set system mode setup

// Load Standard Cell Verilog simulation models
read library -statename STD_LIB \
    /cadence/pdk/gpdk180/verilog/gpdk180_stdcells.v \
    -both

// Load Golden RTL
read design \
    ../../build_rtl/nfp_uminus_single.v \
    ../../build_rtl/nfp_gain_pow2_single.v \
    ../../build_rtl/nfp_relop_single.v \
    ../../build_rtl/nfp_relop_single_block.v \
    ../../build_rtl/nfp_relop_single_block1.v \
    ../../build_rtl/nfp_relop_single_block2.v \
    ../../build_rtl/nfp_add_single.v \
    ../../build_rtl/nfp_sub_single.v \
    ../../build_rtl/nfp_mul_single.v \
    ../../build_rtl/nfp_div_single.v \
    ../../build_rtl/nfp_recip_single.v \
    ../../build_rtl/adaptive_controller_hw.v \
    ../../build_rtl/alamouti_encoder_hw.v \
    ../../build_rtl/alamouti_combiner_hw.v \
    ../../build_rtl/water_filling_hw.v \
    ../../build_rtl/qam_slicer_hw.v \
    ../../build_rtl/mmse_sic_hw.v \
    ../../01_interfaces_and_bus/mimo_axi4_lite_slave.v \
    ../../01_interfaces_and_bus/mimo_axis_stream_adapter.v \
    ../../01_interfaces_and_bus/mimo_interconnect_crossbar.v \
    ../../06_top_integration/mimo_baseband_top.v \
    -golden -verilog -2001

set root module mimo_baseband_top -golden

// ------------------------------------------------------------------------------
// 2. Read Revised Design (Post-Synthesis Netlist)
// ------------------------------------------------------------------------------
read design \
    ../outputs/genus/mimo_baseband_top_synth.v \
    -revised -verilog

set root module mimo_baseband_top -revised

// ------------------------------------------------------------------------------
// 3. Mapping Rules & Naming Normalization
// ------------------------------------------------------------------------------
// Handle bus indexing differences (e.g., reg[0] vs reg_reg_0_)
add renaming rule bus_rule_1 "_reg_%d_" "@1" -revised
add renaming rule bus_rule_2 "_reg$" "" -revised
add renaming rule bus_rule_3 "%d" "[@1]" -revised

// ------------------------------------------------------------------------------
// 4. COMPARE MODE: Key Point Mapping & Boolean Comparison
// ------------------------------------------------------------------------------
set system mode lec

// Map key points: Inputs, Outputs, State Elements (DFFs)
map key points

// Report unmapped points for debugging
report unmapped points -summary > ../reports/lec/lec_unmapped_points.rpt

// Execute full Boolean equivalence proof
add compare points -all
compare

// ------------------------------------------------------------------------------
// 5. Diagnostics & Status Reporting
// ------------------------------------------------------------------------------
report compare data -class nonequivalent -detail > ../reports/lec/lec_noneq_details.rpt
report compare data -summary > ../reports/lec/lec_summary.rpt

// Verify result status
// If all points are Equivalent (EQ), result is PASS
puts "======================================================================"
puts " CONFORMAL LEC VERIFICATION SUMMARY:                                  "
report verification -summary
puts "======================================================================"
