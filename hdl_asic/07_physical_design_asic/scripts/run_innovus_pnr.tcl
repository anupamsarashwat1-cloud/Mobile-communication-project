# ==============================================================================
# Cadence Innovus Physical Implementation (P&R) Script
# Design: 2x2 MIMO Baseband Processor (mimo_baseband_top)
# Process: SCL 180nm / Cadence gpdk180 1P6M (1 Poly, 6 Metal Layers)
# Operating Voltage: 1.8V VDD Core / 3.3V I/O | Target Clock: 100 MHz
# ==============================================================================

set DESIGN_NAME   "mimo_baseband_top"
set SYNTH_NETLIST "../outputs/genus/mimo_baseband_top_synth.v"
set MMMC_FILE     "viewDefinition.tcl"
set TECH_LEF      "/cadence/pdk/gpdk180/lef/gpdk180_tech.lef"
set CELL_LEF      "/cadence/pdk/gpdk180/lef/gpdk180_stdcells.lef"
set GDS_MAP_FILE  "/cadence/pdk/gpdk180/stream/gds2_stream.map"

set REPORT_DIR    "../reports/innovus"
set OUTPUT_DIR    "../outputs/innovus"

file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR

# Set multi-threading (8 CPU cores)
setMultiCpuUsage -localCpu 8

puts "======================================================================"
puts " STEP 1: DESIGN INITIALIZATION & MMMC SETUP                           "
puts "======================================================================"

set init_verilog         $SYNTH_NETLIST
set init_top_cell        $DESIGN_NAME
set init_lef_file        [list $TECH_LEF $CELL_LEF]
set init_pwr_net         "VDD"
set init_gnd_net         "VSS"
set init_mmmc_file       $MMMC_FILE

init_design

# Global net connections for standard cell power rails
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {}
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {}
globalNetConnect VDD -type tiehi -inst * -module {}
globalNetConnect VSS -type tielo -inst * -module {}

puts "======================================================================"
puts " STEP 2: FLOORPLANNING & CORE BOUNDARY ALLOCATION                     "
puts "======================================================================"

# Target 65% initial core density to accommodate CTS buffers and routing
# Aspect ratio 1.0 (square die) with 35 um core-to-IO boundary margin for power rings
floorPlan -site standard_site \
          -r 1.0 0.65 \
          35.0 35.0 35.0 35.0

# Query and print core dimensions
set coreBox [dbGet top.fPlan.coreBox]
puts "Core Boundary Dimensions: $coreBox"

# 2b. Partitioned Subsystem Placement Fences (Matching floorplan_spec.md)
puts "--- Creating Quadrant Placement Fences for Partitioned Subsystems ---"
# Quadrant 1 (North-West): DFE & Host Bus Interface
createInstGroup grp_quad1_interfaces -fence {35.0 800.0 800.0 1565.0}
catch {addInstToInstGroup grp_quad1_interfaces u_interconnect}
catch {addInstToInstGroup grp_quad1_interfaces u_axi_slave}

# Quadrant 2 (North-East): Transmit STBC Encoder & Water-Filling Power Allocator
createInstGroup grp_quad2_transmitter -fence {800.0 800.0 1565.0 1565.0}
catch {addInstToInstGroup grp_quad2_transmitter u_alamouti_encoder}
catch {addInstToInstGroup grp_quad2_transmitter u_water_filling}
catch {addInstToInstGroup grp_quad2_transmitter u_sq1}
catch {addInstToInstGroup grp_quad2_transmitter u_sq2}

# Quadrant 3 (South-West): Cognitive Channel Estimator & Adaptive Rank Controller
createInstGroup grp_quad3_controller -fence {35.0 35.0 800.0 800.0}
catch {addInstToInstGroup grp_quad3_controller u_adaptive_controller}

# Quadrant 4 (South-East): Advanced Receiver (Alamouti MRC, MMSE-SIC Detector & Slicers)
createInstGroup grp_quad4_receiver -fence {800.0 35.0 1565.0 800.0}
catch {addInstToInstGroup grp_quad4_receiver u_alamouti_combiner}
catch {addInstToInstGroup grp_quad4_receiver u_mmse_sic}
catch {addInstToInstGroup grp_quad4_receiver u_slicer_stream1}
catch {addInstToInstGroup grp_quad4_receiver u_slicer_stream2}

puts "======================================================================"
puts " STEP 3: POWER PLANNING (RINGS, STRIPES, RAILS & WELL-TAPS)           "
puts "======================================================================"

# 3a. Add Core Power Rings (Top Metal 5 & Metal 6 for low IR drop)
addRing -nets {VDD VSS} \
        -type core_rings \
        -follow core \
        -layer {top Metal6 bottom Metal6 left Metal5 right Metal5} \
        -width 10.0 \
        -spacing 4.0 \
        -offset 5.0

# 3b. Add Vertical & Horizontal Power Stripes
# Vertical Stripes on Metal 5: Width 6 um, Pitch 50 um
addStripe -nets {VDD VSS} \
          -layer Metal5 \
          -direction vertical \
          -width 6.0 \
          -spacing 3.0 \
          -set_to_set_distance 50.0 \
          -start_offset 15.0

# Horizontal Stripes on Metal 6: Width 6 um, Pitch 60 um
addStripe -nets {VDD VSS} \
          -layer Metal6 \
          -direction horizontal \
          -width 6.0 \
          -spacing 3.0 \
          -set_to_set_distance 60.0 \
          -start_offset 15.0

# 3c. Special Route standard cell followpins (Metal 1 rails)
sroute -connect {blockPin padPin padRing corePin} \
       -layerChangeRange {Metal1 Metal6} \
       -blockPinTarget {nearestTarget} \
       -corePinTarget {firstAfterStriping} \
       -allowJogging 1 \
       -crossoverViaLayerRange {Metal1 Metal6} \
       -nets {VDD VSS}

# 3d. Add Well-Tap Cells to prevent CMOS latch-up (180nm bulk rule: max 30 um)
addWellTap -cell WELLTAP \
           -maxDistance 30.0 \
           -checkerBoard \
           -prefix WELLTAP

puts "======================================================================"
puts " STEP 4: STANDARD CELL PLACEMENT & PRE-CTS TIMING OPTIMIZATION        "
puts "======================================================================"

# Congestion and timing-driven placement configuration
setPlaceMode -timingDriven true \
             -congEffort high \
             -modulePlan true

# Run standard cell placement and concurrent logic optimization
place_opt_design

# Evaluate pre-CTS timing slack
timeDesign -preCTS -outDir ${REPORT_DIR}/preCTS_timing

puts "======================================================================"
puts " STEP 5: CLOCK TREE SYNTHESIS (CCOpt) TARGETING 100 MHZ               "
puts "======================================================================"

# Enable Cadence Concurrent Clock and Optimization (CCOpt)
set_ccopt_property buffer_cells [list CLKBUF_X4 CLKBUF_X8 CLKBUF_X12 CLKBUF_X16]
set_ccopt_property inverter_cells [list CLKINV_X4 CLKINV_X8 CLKINV_X12 CLKINV_X16]

# Define clock targets for 100 MHz (10 ns period)
set_ccopt_property target_skew 0.150       ;# Max skew < 150 ps
set_ccopt_property target_max_trans 0.350  ;# Max slew < 350 ps

# Synthesize clock specifications from SDC definitions
create_ccopt_clock_tree_spec -file ${REPORT_DIR}/clock_tree.spec

# Execute clock tree synthesis and datapath co-optimization
ccopt_design

# Post-CTS timing closure (Setup & Hold optimization)
opt_design -post_cts
opt_design -post_cts -hold

# Evaluate post-CTS timing
timeDesign -postCTS -outDir ${REPORT_DIR}/postCTS_timing
timeDesign -postCTS -hold -outDir ${REPORT_DIR}/postCTS_timing_hold

puts "======================================================================"
puts " STEP 6: DETAILED NANO-ROUTING (1P6M METAL STACK)                     "
puts "======================================================================"

# Configure NanoRoute parameters for 180nm
setNanoRouteMode -quiet -routeWithTimingDriven true \
                        -routeWithSiDriven true \
                        -routeSiEffort high \
                        -routeAntennaEffort high \
                        -routeWithLithoDriven false \
                        -routeBottomRoutingLayer 1 \
                        -routeTopRoutingLayer 6

# Execute full chip routing
route_design

# Post-Route Timing and SI (Signal Integrity) Optimization
opt_design -post_route
opt_design -post_route -hold

# Post-Route timing audit
timeDesign -postRoute -outDir ${REPORT_DIR}/postRoute_timing
timeDesign -postRoute -hold -outDir ${REPORT_DIR}/postRoute_timing_hold

puts "======================================================================"
puts " STEP 7: DECOUPLING CAPACITORS & FILLER CELL INSERTION                 "
puts "======================================================================"

# Add Decoupling Capacitors in empty spaces to absorb 100 MHz dynamic surges
addDeCap -cell {DECAP64 DECAP32 DECAP16} -powerNet VDD -groundNet VSS

# Add standard base and poly filler cells to ensure layer continuity
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} \
          -prefix FILLER \
          -markFixed

puts "======================================================================"
puts " STEP 8: PHYSICAL VERIFICATION (DRC, LVS, ANTENNA CHECKS)             "
puts "======================================================================"

# 8a. Verify DRC (Geometric Design Rules)
verify_drc -report ${REPORT_DIR}/innovus_drc.rpt -limit 1000

# 8b. Verify Connectivity (Opens, shorts, unrouted nets)
verify_connectivity -type all -report ${REPORT_DIR}/innovus_connectivity.rpt

# 8c. Verify Process Antenna Violations (Gate oxide stress)
verifyProcessAntenna -report ${REPORT_DIR}/innovus_antenna.rpt

puts "======================================================================"
puts " STEP 9: SIGNOFF PARASITIC EXTRACTION & DATA EXPORT                   "
puts "======================================================================"

# Extract RC parasitics for Tempus signoff STA
extractRC
rcOut -spef ${OUTPUT_DIR}/${DESIGN_NAME}.spef

# Export final post-route Verilog netlist (with power pins for LVS)
saveNetlist ${OUTPUT_DIR}/${DESIGN_NAME}_pnr.v
saveNetlist -includePhysicalCell {FILL* DECAP* WELLTAP*} \
            ${OUTPUT_DIR}/${DESIGN_NAME}_pnr_lvs.v

# Export Design Exchange Format (DEF)
defOut -floorplan -netlist -routing ${OUTPUT_DIR}/${DESIGN_NAME}.def

# Stream out GDSII for mask fabrication / packaging
streamOut ${OUTPUT_DIR}/${DESIGN_NAME}.gds \
          -mapFile $GDS_MAP_FILE \
          -libName gpdk180 \
          -structureName $DESIGN_NAME \
          -stripes 1 \
          -units 1000

# Save final Innovus database
saveDesign ${OUTPUT_DIR}/${DESIGN_NAME}_final.enc

puts "======================================================================"
puts " INNOVUS IMPLEMENTATION COMPLETED SUCCESSFULLY                        "
puts " Final GDSII:     ${OUTPUT_DIR}/${DESIGN_NAME}.gds                    "
puts " Extracted SPEF:  ${OUTPUT_DIR}/${DESIGN_NAME}.spef                   "
puts " LVS Netlist:     ${OUTPUT_DIR}/${DESIGN_NAME}_pnr_lvs.v              "
puts "======================================================================"
