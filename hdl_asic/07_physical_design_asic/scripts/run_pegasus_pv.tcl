# ==============================================================================
# Cadence Pegasus / PVS Physical Verification Script
# Design: 2x2 MIMO Baseband Processor (mimo_baseband_top)
# Checks: DRC (Design Rules), LVS (Layout vs Schematic), Antenna Rules
# Technology: SCL 180nm / Cadence gpdk180 1P6M
# ==============================================================================

set DESIGN_NAME     "mimo_baseband_top"
set GDS_FILE        "../outputs/innovus/${DESIGN_NAME}.gds"
set SCHEMATIC_SPICE "../outputs/innovus/${DESIGN_NAME}_pnr_lvs.v"
set RULE_DIR        "/cadence/pdk/gpdk180/pvs"
set PV_REPORT_DIR   "../reports/pegasus"

file mkdir $PV_REPORT_DIR

# ------------------------------------------------------------------------------
# 1. DESIGN RULE CHECKING (DRC)
# ------------------------------------------------------------------------------
puts "======================================================================"
puts " RUNNING PEGASUS DRC                                                  "
puts "======================================================================"

exec pegasus -drc \
    -top_cell $DESIGN_NAME \
    -gds $GDS_FILE \
    -rules ${RULE_DIR}/gpdk180_drc.rul \
    -run_dir ${PV_REPORT_DIR}/drc_run \
    -summary_report ${PV_REPORT_DIR}/pegasus_drc_summary.rpt \
    -ui_report ${PV_REPORT_DIR}/pegasus_drc_violations.rpt

# ------------------------------------------------------------------------------
# 2. ANTENNA VIOLATION CHECKING (GATE OXIDE RELIABILITY)
# ------------------------------------------------------------------------------
puts "======================================================================"
puts " RUNNING PEGASUS ANTENNA CHECK                                        "
puts "======================================================================"

exec pegasus -antenna \
    -top_cell $DESIGN_NAME \
    -gds $GDS_FILE \
    -rules ${RULE_DIR}/gpdk180_antenna.rul \
    -run_dir ${PV_REPORT_DIR}/antenna_run \
    -summary_report ${PV_REPORT_DIR}/pegasus_antenna_summary.rpt

# ------------------------------------------------------------------------------
# 3. LAYOUT VERSUS SCHEMATIC (LVS)
# ------------------------------------------------------------------------------
puts "======================================================================"
puts " RUNNING PEGASUS LVS                                                  "
puts "======================================================================"

exec pegasus -lvs \
    -top_cell $DESIGN_NAME \
    -gds $GDS_FILE \
    -source_cdl $SCHEMATIC_SPICE \
    -source_top_cell $DESIGN_NAME \
    -rules ${RULE_DIR}/gpdk180_lvs.rul \
    -run_dir ${PV_REPORT_DIR}/lvs_run \
    -summary_report ${PV_REPORT_DIR}/pegasus_lvs_summary.rpt

puts "======================================================================"
puts " PHYSICAL VERIFICATION COMPLETED                                      "
puts " Review reports in: ${PV_REPORT_DIR}                                  "
puts "======================================================================"
