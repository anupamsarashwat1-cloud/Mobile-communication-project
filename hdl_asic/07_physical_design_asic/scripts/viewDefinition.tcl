# ==============================================================================
# Innovus Multi-Mode Multi-Corner (MMMC) Configuration
# Technology: 180nm CMOS (Core: 1.8V, I/O: 3.3V)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Library Sets
# ------------------------------------------------------------------------------
create_library_set -name lib_slow \
    -timing [list /cadence/pdk/gpdk180/lib/slow_vdd1v8_125c.lib]

create_library_set -name lib_fast \
    -timing [list /cadence/pdk/gpdk180/lib/fast_vdd1v8_m40c.lib]

create_library_set -name lib_typ \
    -timing [list /cadence/pdk/gpdk180/lib/typical_vdd1v8_25c.lib]

# ------------------------------------------------------------------------------
# 2. RC Corners (Quantus / Tech CapTables)
# ------------------------------------------------------------------------------
create_rc_corner -name rc_worst \
    -cap_table /cadence/pdk/gpdk180/captable/gpdk180_worst.capTable \
    -T 125

create_rc_corner -name rc_best \
    -cap_table /cadence/pdk/gpdk180/captable/gpdk180_best.capTable \
    -T -40

create_rc_corner -name rc_typ \
    -cap_table /cadence/pdk/gpdk180/captable/gpdk180_typical.capTable \
    -T 25

# ------------------------------------------------------------------------------
# 3. Operating Conditions & Delay Corners
# ------------------------------------------------------------------------------
create_op_cond -name op_slow -process 1.0 -voltage 1.62 -temperature 125
create_op_cond -name op_fast -process 1.0 -voltage 1.98 -temperature -40
create_op_cond -name op_typ  -process 1.0 -voltage 1.80 -temperature 25

create_delay_corner -name dc_slow \
    -library_set lib_slow \
    -rc_corner rc_worst \
    -opcond op_slow

create_delay_corner -name dc_fast \
    -library_set lib_fast \
    -rc_corner rc_best \
    -opcond op_fast

create_delay_corner -name dc_typ \
    -library_set lib_typ \
    -rc_corner rc_typ \
    -opcond op_typ

# ------------------------------------------------------------------------------
# 4. Constraint Modes
# ------------------------------------------------------------------------------
create_constraint_mode -name cm_functional \
    -sdc_files [list ../sdc/mimo_baseband_100mhz.sdc]

# ------------------------------------------------------------------------------
# 5. Analysis Views
# ------------------------------------------------------------------------------
# Setup analysis view: Worst-Case corner (Slow silicon, min voltage 1.62V, max temp 125C, Cmax)
create_analysis_view -name view_setup \
    -delay_corner dc_slow \
    -constraint_mode cm_functional

# Hold analysis view: Best-Case corner (Fast silicon, max voltage 1.98V, min temp -40C, Cmin)
create_analysis_view -name view_hold \
    -delay_corner dc_fast \
    -constraint_mode cm_functional

# Active views assignment
set_analysis_view -setup [list view_setup] -hold [list view_hold]
