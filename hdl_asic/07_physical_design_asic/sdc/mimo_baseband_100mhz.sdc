# ==============================================================================
# SDC Design Constraints for 2x2 MIMO Baseband Processor
# Target Technology: SCL 180nm CMOS / Cadence gpdk180 Baseline
# Nominal Operating Voltage: 1.8V (Core), 3.3V (I/O)
# Target Clock Frequency: 100 MHz (Clock Period = 10.0 ns)
# ==============================================================================

# Reset all prior constraints
reset_design

# ------------------------------------------------------------------------------
# 1. Primary Clock Definition
# ------------------------------------------------------------------------------
# Master system clock: 100 MHz -> Period = 10.00 ns, 50% duty cycle
create_clock -name sys_clk -period 10.00 -waveform {0.00 5.00} [get_ports clk]

# Virtual reference clock for off-chip interface timing modeling
create_clock -name v_sys_clk -period 10.00 -waveform {0.00 5.00}

# ------------------------------------------------------------------------------
# 2. Clock Tree Uncertainty, Jitter, and Transition
# ------------------------------------------------------------------------------
# 20% setup margin (2.0 ns over-constraint) + 200 ps clock jitter/skew = 2.20 ns
set_clock_uncertainty -setup 2.20 [get_clocks sys_clk]

# Hold uncertainty accounts for internal clock distribution skew (150 ps)
set_clock_uncertainty -hold  0.15 [get_clocks sys_clk]

# Max slew rate (transition time) on clock network
set_clock_transition 0.35 [get_clocks sys_clk]

# Clock latency modeling before CTS (Pre-CTS estimated insertion delay)
set_clock_latency -source -early 0.80 [get_clocks sys_clk]
set_clock_latency -source -late  1.20 [get_clocks sys_clk]

# ------------------------------------------------------------------------------
# 3. I/O Timing Constraints
# ------------------------------------------------------------------------------
# All inputs except primary clock
set input_ports [remove_from_collection [all_inputs] [get_ports clk]]

# Input delay budget (relative to virtual clock v_sys_clk):
# Board trace delay + off-chip launch delay: Max 3.0 ns (30% Tclk), Min 0.5 ns
set_input_delay -clock v_sys_clk -max 3.00 $input_ports
set_input_delay -clock v_sys_clk -min 0.50 $input_ports

# Output delay budget (relative to virtual clock v_sys_clk):
# External setup time + board trace propagation: Max 3.0 ns (30% Tclk), Min 0.5 ns
set_output_delay -clock v_sys_clk -max 3.00 [all_outputs]
set_output_delay -clock v_sys_clk -min 0.50 [all_outputs]

# ------------------------------------------------------------------------------
# 4. Drive Strength & Output Load Modeling
# ------------------------------------------------------------------------------
# Input driving cell model (standard 180nm inverter/buffer drive, ~4X drive)
set_driving_cell -lib_cell INVX4 -pin Y -library [get_libs -of_objects [get_lib_cells */INVX4]] $input_ports

# Output load capacitance:
# 50 fF for internal core macro boundary testing;
# 10 pF when directly driving off-chip I/O pads
set_load -pin_load 0.050 [all_outputs]

# ------------------------------------------------------------------------------
# 5. Design Rule Constraints (DRC)
# ------------------------------------------------------------------------------
# Max transition time for any internal signal net (500 ps)
set_max_transition 0.50 [current_design]

# Max fanout limit per net to enforce buffer insertion during synthesis
set_max_fanout 16 [current_design]

# Max capacitance limit to prevent severe slew degradation
set_max_capacitance 0.200 [current_design]

# ------------------------------------------------------------------------------
# 6. Timing Exceptions: False Paths & Multicycle Paths
# ------------------------------------------------------------------------------
# Reset signals are unconstrained for datapath paths
if {[sizeof_collection [get_ports -quiet rst]] > 0} {
    set_false_path -from [get_ports rst]
}
if {[sizeof_collection [get_ports -quiet rst_n]] > 0} {
    set_false_path -from [get_ports rst_n]
}

# Quasi-static configuration registers (e.g. AXI4-Lite threshold registers)
# These registers are programmed prior to streaming bursts and remain steady.
# Setting multicycle path of 2 cycles relaxes placement pressure on non-critical control paths.
set static_regs [get_pins -quiet {*reg_thresh*/Q *reg_config*/Q *reg_power_budget*/Q}]
if {[sizeof_collection $static_regs] > 0} {
    set_multicycle_path 2 -setup -from $static_regs
    set_multicycle_path 1 -hold  -from $static_regs
}

# Case analysis for test / scan modes (if applicable)
# set_case_analysis 0 [get_ports -quiet scan_enable]
