################################################################################
# Synopsys Design Constraints (SDC) for MIMO Baseband Accelerator
# Target Technology: SCL 180nm / Cadence 180nm PDK (1.8V Core, 3.3V I/O)
# Author: Anupam Saraswat & Capstone Team | SMVDU
################################################################################

# 1. Clock Definition
# Target Frequency: 100 MHz (Clock Period = 10.0 ns)
create_clock -name "clk_core" -period 10.0 -waveform {0.0 5.0} [get_ports clk]

# Clock Uncertainty (Jitter + Skew budget for 180nm CTS)
set_clock_uncertainty -setup 0.300 [get_clocks clk_core]
set_clock_uncertainty -hold  0.150 [get_clocks clk_core]

# Clock Transition (Slew Rate constraint)
set_clock_transition 0.200 [get_clocks clk_core]

# 2. Reset and Control False Paths
# Asynchronous active-low reset assertion is false path; removal is synchronized internally
set_false_path -from [get_ports rst_n]

# 3. Input Delays (AXI4-Lite & AXI4-Stream)
# Assuming 30% external budget (3.0 ns)
set_input_delay -clock clk_core -max 3.0 [get_ports {s_axi_ctrl_* rx_axis_* mode_override_*}]
set_input_delay -clock clk_core -min 0.5 [get_ports {s_axi_ctrl_* rx_axis_* mode_override_*}]

# 4. Output Delays
# Assuming 30% external budget (3.0 ns)
set_output_delay -clock clk_core -max 3.0 [get_ports {tx_axis_* s_axi_ctrl_rdata s_axi_ctrl_rvalid status_*}]
set_output_delay -clock clk_core -min 0.5 [get_ports {tx_axis_* s_axi_ctrl_rdata s_axi_ctrl_rvalid status_*}]

# 5. Output Load and Driving Cell
# Standard inverter drive (INVX4) and 20 fF capacitive load per pin
set_load -pin_load 0.020 [all_outputs]
set_driving_cell -lib_cell INVX4 [all_inputs -no_clocks]

# 6. Operating Conditions (Worst-Case PVT Corner)
# Slow-Slow (SS), 1.62V (10% drop), 125 deg C
set_operating_conditions -max "slow_1.62v_125c" -min "fast_1.98v_0c"
