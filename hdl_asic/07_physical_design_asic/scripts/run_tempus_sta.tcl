# ==============================================================================
# Cadence Tempus Signoff Static Timing Analysis (STA) Script
# Design: 2x2 MIMO Baseband Processor (mimo_baseband_top)
# Technology: SCL 180nm / Cadence gpdk180 Standard Cells
# Clock: 100 MHz (10.0 ns) | Setup Margin Target: >= 2.0 ns
# ==============================================================================

set DESIGN_NAME   "mimo_baseband_top"
set NETLIST       "../outputs/innovus/mimo_baseband_top_pnr.v"
set SPEF_FILE     "../outputs/innovus/mimo_baseband_top.spef"
set SDC_FILE      "../sdc/mimo_baseband_100mhz.sdc"
set REPORT_DIR    "../reports/tempus"

file mkdir $REPORT_DIR

# Set multi-threading (8 CPU cores)
set_multi_cpu_usage -local_cpu 8

puts "======================================================================"
puts " STEP 1: LOAD TIMING LIBRARIES (MULTI-CORNER)                         "
puts "======================================================================"

set LIB_DIR "/cadence/pdk/gpdk180/lib"
read_lib -slow "${LIB_DIR}/slow_vdd1v8_125c.lib"
read_lib -fast "${LIB_DIR}/fast_vdd1v8_m40c.lib"
read_lib -typical "${LIB_DIR}/typical_vdd1v8_25c.lib"

puts "======================================================================"
puts " STEP 2: LOAD NETLIST & ANNOTATE EXTRACTED SPEF PARASITICS            "
puts "======================================================================"

read_verilog $NETLIST
set_top_module $DESIGN_NAME

# Annotate post-route detailed parasitics (coupling caps and resistance)
read_spef $SPEF_FILE

puts "======================================================================"
puts " STEP 3: APPLY TIMING CONSTRAINTS & AUDIT COVERAGE                    "
puts "======================================================================"

read_sdc $SDC_FILE

# Verify constraint completeness
check_timing -verbose > ${REPORT_DIR}/tempus_timing_audit.rpt

puts "======================================================================"
puts " STEP 4: SIGNOFF SETUP & HOLD TIMING ANALYSIS (GBA & PBA)              "
puts "======================================================================"

# 4a. Worst-Case Corner Setup Analysis (SS, 1.62V, 125°C)
set_operating_conditions -analysis_type on_chip_variation slow_vdd1v8_125c

# Run Graph-Based Analysis (GBA)
report_timing -check_type setup -max_paths 50 -nworst 1 \
    > ${REPORT_DIR}/tempus_setup_gba_worst50.rpt

# Run Path-Based Analysis (PBA) for highest signoff accuracy (removes pessimism)
report_timing -check_type setup -pba_mode path -max_paths 20 \
    > ${REPORT_DIR}/tempus_setup_pba_signoff.rpt

# 4b. Best-Case Corner Hold Analysis (FF, 1.98V, -40°C)
set_operating_conditions -analysis_type on_chip_variation fast_vdd1v8_m40c

report_timing -check_type hold -max_paths 50 -nworst 1 \
    > ${REPORT_DIR}/tempus_hold_gba_worst50.rpt

report_timing -check_type hold -pba_mode path -max_paths 20 \
    > ${REPORT_DIR}/tempus_hold_pba_signoff.rpt

puts "======================================================================"
puts " STEP 5: CLOCK SKEW & DESIGN RULE VIOLATION AUDIT                     "
puts "======================================================================"

# Clock Tree Skew & Latency Report
report_clock_timing -type skew -nworst 20 > ${REPORT_DIR}/tempus_clock_skew.rpt
report_clock_timing -type latency -nworst 20 > ${REPORT_DIR}/tempus_clock_latency.rpt

# Design Rule Constraints (DRC): Max Slew / Max Capacitance / Max Fanout
report_constraint -all_violators -max_transition > ${REPORT_DIR}/tempus_slew_violators.rpt
report_constraint -all_violators -max_capacitance > ${REPORT_DIR}/tempus_cap_violators.rpt
report_constraint -all_violators -max_fanout > ${REPORT_DIR}/tempus_fanout_violators.rpt

# Generate overall timing summary
report_analysis_summary > ${REPORT_DIR}/tempus_timing_summary.rpt

puts "======================================================================"
puts " TEMPUS SIGNOFF STA COMPLETED                                         "
puts " Check ${REPORT_DIR}/tempus_setup_pba_signoff.rpt for setup slack     "
puts " Check ${REPORT_DIR}/tempus_hold_pba_signoff.rpt for hold slack       "
puts "======================================================================"
