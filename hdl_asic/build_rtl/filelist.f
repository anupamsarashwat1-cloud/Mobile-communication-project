# ==============================================================================
# File: filelist.f
# Project: SMVDU-MIMO-180 Standalone 2x2 MIMO Baseband Processor ASIC
# Target: Cadence Genus / ModelSim / QuestaSim Compilation Filelist
# ==============================================================================

# IEEE-754 Single-Precision Native Floating Point (NFP) Standard-Cell Cores
hdl_asic/build_rtl/nfp_uminus_single.v
hdl_asic/build_rtl/nfp_gain_pow2_single.v
hdl_asic/build_rtl/nfp_relop_single.v
hdl_asic/build_rtl/nfp_relop_single_block.v
hdl_asic/build_rtl/nfp_relop_single_block1.v
hdl_asic/build_rtl/nfp_relop_single_block2.v
hdl_asic/build_rtl/nfp_add_single.v
hdl_asic/build_rtl/nfp_sub_single.v
hdl_asic/build_rtl/nfp_mul_single.v
hdl_asic/build_rtl/nfp_div_single.v
hdl_asic/build_rtl/nfp_recip_single.v

# HDL Coder Baseband Subsystem Kernels
hdl_asic/build_rtl/adaptive_controller_hw.v
hdl_asic/build_rtl/alamouti_encoder_hw.v
hdl_asic/build_rtl/alamouti_combiner_hw.v
hdl_asic/build_rtl/water_filling_hw.v
hdl_asic/build_rtl/qam_slicer_hw.v
hdl_asic/build_rtl/mmse_sic_hw.v

# Subsystem 01: Host Bus Interfaces & Interconnect
hdl_asic/01_interfaces_and_bus/mimo_axi4_lite_slave.v
hdl_asic/01_interfaces_and_bus/mimo_axis_stream_adapter.v
hdl_asic/01_interfaces_and_bus/mimo_interconnect_crossbar.v

# Subsystem 06: Top-Level ASIC Integration Wrapper
hdl_asic/06_top_integration/mimo_baseband_top.v
