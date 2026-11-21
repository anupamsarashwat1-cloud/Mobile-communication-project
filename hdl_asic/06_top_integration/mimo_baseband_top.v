// ============================================================================
// File: mimo_baseband_top.v
// Project: SMVDU-MIMO-180 Standalone 2x2 MIMO Baseband Processor ASIC
// Institution: Shri Mata Vaishno Devi University (SMVDU)
// Course: B.Tech Capstone Project (ECL DC 401 Mobile Communication)
// Standard: IEEE 1364-2001 Verilog Synthesizable RTL
// Target Technology: SCL 180nm CMOS (1P6M) / Cadence gpdk180 Virtual Prototype
// ============================================================================
// Description:
//   Master Top-Level Integration Wrapper for the SMVDU-MIMO-180 ASIC.
//   Integrates MathWorks HDL Coder generated baseband processing kernels:
//     1. STBC Transmit Space-Time Block Encoder (alamouti_encoder_hw)
//     2. STBC Receive Maximal Ratio Combining Engine (alamouti_combiner_hw)
//     3. Non-Linear Ordered MMSE-SIC Detection Engine (mmse_sic_hw)
//     4. Pipelined 2-Stage Water-Filling Power Allocator (water_filling_hw)
//     5. Real-Time Dynamic Mode & Rank Adaptation Controller (adaptive_controller_hw)
//     6. Euclidean Constellation Decision Slicers (qam_slicer_hw)
//     7. Memory-Mapped AXI4-Lite Control, Status, and Telemetry Registers (CSR)
// ============================================================================

`timescale 1 ns / 1 ns

module mimo_baseband_top (
    // ------------------------------------------------------------------------
    // Clock & System Control
    // ------------------------------------------------------------------------
    input  wire        clk,                  // Master Clock (100 MHz nominal)
    input  wire        rst,                  // Synchronous Reset (Active-High, per HDL Coder spec)
    input  wire        clk_enable,           // Master Clock Enable

    // ------------------------------------------------------------------------
    // AXI4-Lite Memory-Mapped Slave Interface (Control, Config, Status)
    // ------------------------------------------------------------------------
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    // ------------------------------------------------------------------------
    // Baseband Transmitter (TX) Data Ports (IEEE-754 Single-Precision 32-bit)
    // ------------------------------------------------------------------------
    input  wire        tx_valid,             // Transmit Input Valid Strobe
    output wire        tx_ready,             // Transmitter Ready for New Symbols
    input  wire [31:0] tx_s1_re,             // Stream 1 In-Phase Component
    input  wire [31:0] tx_s1_im,             // Stream 1 Quadrature Component
    input  wire [31:0] tx_s2_re,             // Stream 2 In-Phase Component
    input  wire [31:0] tx_s2_im,             // Stream 2 Quadrature Component

    // Transmit RF DAC Outputs (Antenna 1 & 2 across Time Slots 1 & 2)
    output wire        tx_rf_valid,          // RF Output Valid Strobe
    output wire [31:0] tx_ant1_t1_re,        // Antenna 1, Slot 1 Real
    output wire [31:0] tx_ant1_t1_im,        // Antenna 1, Slot 1 Imag
    output wire [31:0] tx_ant2_t1_re,        // Antenna 2, Slot 1 Real
    output wire [31:0] tx_ant2_t1_im,        // Antenna 2, Slot 1 Imag
    output wire [31:0] tx_ant1_t2_re,        // Antenna 1, Slot 2 Real
    output wire [31:0] tx_ant1_t2_im,        // Antenna 1, Slot 2 Imag
    output wire [31:0] tx_ant2_t2_re,        // Antenna 2, Slot 2 Real
    output wire [31:0] tx_ant2_t2_im,        // Antenna 2, Slot 2 Imag

    // ------------------------------------------------------------------------
    // Baseband Receiver (RX) Data Ports (IEEE-754 Single-Precision 32-bit)
    // ------------------------------------------------------------------------
    input  wire        rx_valid,             // Receive Sample Valid Strobe
    // Antenna 1 & 2 Time Slot 1 Received Baseband Signals
    input  wire [31:0] rx_ant1_t1_re,
    input  wire [31:0] rx_ant1_t1_im,
    input  wire [31:0] rx_ant2_t1_re,
    input  wire [31:0] rx_ant2_t1_im,
    // Antenna 1 & 2 Time Slot 2 Received Baseband Signals (used in STBC mode)
    input  wire [31:0] rx_ant1_t2_re,
    input  wire [31:0] rx_ant1_t2_im,
    input  wire [31:0] rx_ant2_t2_re,
    input  wire [31:0] rx_ant2_t2_im,

    // ------------------------------------------------------------------------
    // Channel State Information (CSI) 2x2 Matrix H (IEEE-754 Single-Precision)
    // ------------------------------------------------------------------------
    input  wire [31:0] csi_h11_re,
    input  wire [31:0] csi_h11_im,
    input  wire [31:0] csi_h12_re,
    input  wire [31:0] csi_h12_im,
    input  wire [31:0] csi_h21_re,
    input  wire [31:0] csi_h21_im,
    input  wire [31:0] csi_h22_re,
    input  wire [31:0] csi_h22_im,

    // Channel Singular Values & Operational Environment
    input  wire [31:0] csi_sigma1,           // Largest Singular Value (sigma_1)
    input  wire [31:0] csi_sigma2,           // Smallest Singular Value (sigma_2)
    input  wire [31:0] sys_snr_linear,       // Operating Linear SNR (e.g., 10.0 for 10 dB)
    input  wire [31:0] sys_noise_var,        // Noise Variance sigma_n^2

    // ------------------------------------------------------------------------
    // Receiver Decoded & Sliced Outputs (IEEE-754 Single-Precision 32-bit)
    // ------------------------------------------------------------------------
    output wire        rx_out_valid,         // Receiver Output Valid Strobe
    output wire [31:0] rx_s1_hat_re,         // Stream 1 Sliced Symbol Real
    output wire [31:0] rx_s1_hat_im,         // Stream 1 Sliced Symbol Imag
    output wire [31:0] rx_s2_hat_re,         // Stream 2 Sliced Symbol Real
    output wire [31:0] rx_s2_hat_im,         // Stream 2 Sliced Symbol Imag
    output wire [31:0] rx_s1_raw_re,         // Stream 1 Soft MMSE/MRC Output Real
    output wire [31:0] rx_s1_raw_im,         // Stream 1 Soft MMSE/MRC Output Imag
    output wire [31:0] rx_s2_raw_re,         // Stream 2 Soft MMSE/MRC Output Real
    output wire [31:0] rx_s2_raw_im,         // Stream 2 Soft MMSE/MRC Output Imag

    // ------------------------------------------------------------------------
    // ASIC Real-Time Telemetry & Status Flags
    // ------------------------------------------------------------------------
    output wire        telemetry_mode,       // 0: STBC Alamouti, 1: Spatial Multiplexing
    output wire        telemetry_kappa_high, // 1: Condition Number exceeds threshold
    output wire [31:0] telemetry_active_rank,// 1 or 2 active streams
    output wire [31:0] telemetry_p1_power,   // Power allocated to Stream 1
    output wire [31:0] telemetry_p2_power,   // Power allocated to Stream 2
    output wire        irq_frame_done        // Hardware Interrupt: Frame Processing Complete
);

    // ========================================================================
    // Internal Parameter Definitions & Default Constants
    // ========================================================================
    // IEEE-754 Single Constants:
    // 4.5f  = 32'h4090_0000 (Default Condition Number Threshold)
    // 6.31f = 32'h40CA_3D71 (Default SNR Threshold = 8.0 dB in linear)
    // 1.0f  = 32'h3F80_0000 (Default Total Power P_total = 1.0)
    // 4.0f  = 32'h4080_0000 (Default QPSK Modulation Order)
    localparam [31:0] DEFAULT_KAPPA_THRESH = 32'h4090_0000;
    localparam [31:0] DEFAULT_SNR_THRESH   = 32'h40CA_3D71;
    localparam [31:0] DEFAULT_P_TOTAL      = 32'h3F80_0000;
    localparam [31:0] DEFAULT_MOD_ORDER    = 32'h4080_0000;

    // ========================================================================
    // AXI4-Lite Slave Register Interface (CSR Architecture)
    // ========================================================================
    // Register Map:
    // 0x00: CONTROL_REG       [0: Enable, 1: Force Mode Override, 2: Forced Mode, 3: Soft Reset]
    // 0x04: STATUS_REG        [0: Busy, 1: Mode, 2: Kappa Alert, [4:3]: Active Rank]
    // 0x08: KAPPA_THRESH_REG  (IEEE-754 single, default 4.5)
    // 0x0C: SNR_THRESH_REG    (IEEE-754 single, default 6.31 = 8.0 dB)
    // 0x10: TOTAL_POWER_REG   (IEEE-754 single, default 1.0)
    // 0x14: MOD_ORDER_REG     (IEEE-754 single, 4.0 for QPSK, 16.0 for 16-QAM)
    // 0x18: TELEMETRY_P1_REG  (Read-Only: Allocated P1)
    // 0x1C: TELEMETRY_P2_REG  (Read-Only: Allocated P2)
    // 0x20: CYCLE_COUNT_REG   (Read-Only: Diagnostic counter)

    reg [31:0] reg_control;
    reg [31:0] reg_kappa_thresh;
    reg [31:0] reg_snr_thresh;
    reg [31:0] reg_total_power;
    reg [31:0] reg_mod_order;
    reg [31:0] reg_cycle_count;

    reg        axi_awready;
    reg        axi_wready;
    reg        axi_bvalid;
    reg        axi_arready;
    reg [31:0] axi_rdata;
    reg        axi_rvalid;

    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = 2'b00; // OKAY
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = 2'b00; // OKAY
    assign s_axi_rvalid  = axi_rvalid;

    // AXI4-Lite Write Handshake & Registers
    always @(posedge clk) begin
        if (rst) begin
            axi_awready      <= 1'b0;
            axi_wready       <= 1'b0;
            axi_bvalid       <= 1'b0;
            reg_control      <= 32'h0000_0001; // Enabled by default
            reg_kappa_thresh <= DEFAULT_KAPPA_THRESH;
            reg_snr_thresh   <= DEFAULT_SNR_THRESH;
            reg_total_power  <= DEFAULT_P_TOTAL;
            reg_mod_order    <= DEFAULT_MOD_ORDER;
        end else begin
            // Write Address Ready
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end

            // Write Data Ready
            if (~axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end

            // Register Write Execution
            if (s_axi_awvalid && s_axi_wvalid && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
                case (s_axi_awaddr[5:0])
                    6'h00: reg_control      <= s_axi_wdata;
                    6'h08: reg_kappa_thresh <= s_axi_wdata;
                    6'h0C: reg_snr_thresh   <= s_axi_wdata;
                    6'h10: reg_total_power  <= s_axi_wdata;
                    6'h14: reg_mod_order    <= s_axi_wdata;
                    default: ;
                endcase
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Handshake
    always @(posedge clk) begin
        if (rst) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rdata   <= 32'd0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
            end

            if (s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                case (s_axi_araddr[5:0])
                    6'h00: axi_rdata <= reg_control;
                    6'h04: axi_rdata <= {27'd0, telemetry_active_rank[1:0], telemetry_kappa_high, telemetry_mode, 1'b1};
                    6'h08: axi_rdata <= reg_kappa_thresh;
                    6'h0C: axi_rdata <= reg_snr_thresh;
                    6'h10: axi_rdata <= reg_total_power;
                    6'h14: axi_rdata <= reg_mod_order;
                    6'h18: axi_rdata <= telemetry_p1_power;
                    6'h1C: axi_rdata <= telemetry_p2_power;
                    6'h20: axi_rdata <= reg_cycle_count;
                    default: axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end else if (s_axi_rready && axi_rvalid) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Diagnostic Cycle Counter
    always @(posedge clk) begin
        if (rst) begin
            reg_cycle_count <= 32'd0;
        end else begin
            reg_cycle_count <= reg_cycle_count + 1'b1;
        end
    end

    // ========================================================================
    // Subsystem 1: Real-Time Dynamic Mode & Rank Adaptation Controller
    // ========================================================================
    wire        ctrl_ce_out;
    wire [31:0] ctrl_selected_mode_fp;
    wire        ctrl_kappa_is_high;
    wire [31:0] ctrl_active_streams;

    adaptive_controller_hw u_adaptive_controller (
        .clk              (clk),
        .rst              (rst),
        .clk_enable       (clk_enable),
        .sigma1           (csi_sigma1),
        .sigma2           (csi_sigma2),
        .snr_linear       (sys_snr_linear),
        .kappa_thresh     (reg_kappa_thresh),
        .snr_thresh_linear(reg_snr_thresh),
        .ce_out           (ctrl_ce_out),
        .selected_mode    (ctrl_selected_mode_fp),
        .kappa_is_high    (ctrl_kappa_is_high),
        .active_streams   (ctrl_active_streams)
    );

    // Mode multiplexer: software override support
    // reg_control[1]: override enable, reg_control[2]: forced mode
    wire current_mode = (reg_control[1]) ? reg_control[2] : (ctrl_selected_mode_fp != 32'h0);

    assign telemetry_mode        = current_mode;
    assign telemetry_kappa_high  = ctrl_kappa_is_high;
    assign telemetry_active_rank = ctrl_active_streams;

    // ========================================================================
    // Subsystem 2: Water-Filling Power Allocation Engine
    // ========================================================================
    // Compute singular value squares: sigma1_sq, sigma2_sq
    // Note: If external sigma_sq is directly available, it routes in; here we use
    // NFP multipliers or direct square inputs.
    wire        wf_ce_out;
    wire [31:0] wf_p1;
    wire [31:0] wf_p2;
    wire [31:0] wf_active_rank;

    // Direct singular value squares computation
    wire [31:0] sigma1_sq_wire;
    wire [31:0] sigma2_sq_wire;

    nfp_mul_single u_sq1 (
        .nfp_in1(csi_sigma1),
        .nfp_in2(csi_sigma1),
        .nfp_out(sigma1_sq_wire)
    );

    nfp_mul_single u_sq2 (
        .nfp_in2(csi_sigma2),
        .nfp_in1(csi_sigma2),
        .nfp_out(sigma2_sq_wire)
    );

    water_filling_hw u_water_filling (
        .clk        (clk),
        .rst        (rst),
        .clk_enable (clk_enable),
        .sigma1_sq  (sigma1_sq_wire),
        .sigma2_sq  (sigma2_sq_wire),
        .P_total    (reg_total_power),
        .noise_var  (sys_noise_var),
        .ce_out     (wf_ce_out),
        .P1         (wf_p1),
        .P2         (wf_p2),
        .active_rank(wf_active_rank)
    );

    assign telemetry_p1_power = wf_p1;
    assign telemetry_p2_power = wf_p2;

    // ========================================================================
    // Subsystem 3: Transmitter Path (STBC vs Spatial Multiplexing)
    // ========================================================================
    wire        stbc_tx_ce_out;
    wire [31:0] stbc_x1_t1_re, stbc_x1_t1_im;
    wire [31:0] stbc_x2_t1_re, stbc_x2_t1_im;
    wire [31:0] stbc_x1_t2_re, stbc_x1_t2_im;
    wire [31:0] stbc_x2_t2_re, stbc_x2_t2_im;

    alamouti_encoder_hw u_alamouti_encoder (
        .clk       (clk),
        .rst       (rst),
        .clk_enable(clk_enable && tx_valid),
        .s1_re     (tx_s1_re),
        .s1_im     (tx_s1_im),
        .s2_re     (tx_s2_re),
        .s2_im     (tx_s2_im),
        .ce_out    (stbc_tx_ce_out),
        .x1_t1_re  (stbc_x1_t1_re),
        .x1_t1_im  (stbc_x1_t1_im),
        .x2_t1_re  (stbc_x2_t1_re),
        .x2_t1_im  (stbc_x2_t1_im),
        .x1_t2_re  (stbc_x1_t2_re),
        .x1_t2_im  (stbc_x1_t2_im),
        .x2_t2_re  (stbc_x2_t2_re),
        .x2_t2_im  (stbc_x2_t2_im)
    );

    // Transmit Multiplexing:
    // In Mode 0 (STBC): 2 slots are emitted across both antennas.
    // In Mode 1 (SM): Symbols are streamed directly on slot 1, slot 2 holds next stream.
    assign tx_ant1_t1_re = (current_mode == 1'b0) ? stbc_x1_t1_re : tx_s1_re;
    assign tx_ant1_t1_im = (current_mode == 1'b0) ? stbc_x1_t1_im : tx_s1_im;
    assign tx_ant2_t1_re = (current_mode == 1'b0) ? stbc_x2_t1_re : tx_s2_re;
    assign tx_ant2_t1_im = (current_mode == 1'b0) ? stbc_x2_t1_im : tx_s2_im;

    assign tx_ant1_t2_re = (current_mode == 1'b0) ? stbc_x1_t2_re : 32'd0;
    assign tx_ant1_t2_im = (current_mode == 1'b0) ? stbc_x1_t2_im : 32'd0;
    assign tx_ant2_t2_re = (current_mode == 1'b0) ? stbc_x2_t2_re : 32'd0;
    assign tx_ant2_t2_im = (current_mode == 1'b0) ? stbc_x2_t2_im : 32'd0;

    assign tx_rf_valid = stbc_tx_ce_out || (current_mode == 1'b1 && tx_valid);
    assign tx_ready    = clk_enable && reg_control[0];

    // ========================================================================
    // Subsystem 4: Receiver Path (Alamouti MRC vs Non-Linear MMSE-SIC)
    // ========================================================================
    // Mode 0: Alamouti Combiner
    wire        stbc_rx_ce_out;
    wire [31:0] stbc_s1_re, stbc_s1_im;
    wire [31:0] stbc_s2_re, stbc_s2_im;

    alamouti_combiner_hw u_alamouti_combiner (
        .clk       (clk),
        .rst       (rst),
        .clk_enable(clk_enable && (current_mode == 1'b0)),
        .r1_t1_re  (rx_ant1_t1_re),
        .r1_t1_im  (rx_ant1_t1_im),
        .r2_t1_re  (rx_ant2_t1_re),
        .r2_t1_im  (rx_ant2_t1_im),
        .r1_t2_re  (rx_ant1_t2_re),
        .r1_t2_im  (rx_ant1_t2_im),
        .r2_t2_re  (rx_ant2_t2_re),
        .r2_t2_im  (rx_ant2_t2_im),
        .h11_re    (csi_h11_re),
        .h11_im    (csi_h11_im),
        .h12_re    (csi_h12_re),
        .h12_im    (csi_h12_im),
        .h21_re    (csi_h21_re),
        .h21_im    (csi_h21_im),
        .h22_re    (csi_h22_re),
        .h22_im    (csi_h22_im),
        .ce_out    (stbc_rx_ce_out),
        .s1_re     (stbc_s1_re),
        .s1_im     (stbc_s1_im),
        .s2_re     (stbc_s2_re),
        .s2_im     (stbc_s2_im)
    );

    // Mode 1: Ordered MMSE-SIC Receiver
    wire        sic_rx_ce_out;
    wire [31:0] sic_s1_re, sic_s1_im;
    wire [31:0] sic_s2_re, sic_s2_im;

    mmse_sic_hw u_mmse_sic (
        .clk       (clk),
        .rst       (rst),
        .clk_enable(clk_enable && (current_mode == 1'b1)),
        .r1_re     (rx_ant1_t1_re),
        .r1_im     (rx_ant1_t1_im),
        .r2_re     (rx_ant2_t1_re),
        .r2_im     (rx_ant2_t1_im),
        .h11_re    (csi_h11_re),
        .h11_im    (csi_h11_im),
        .h12_re    (csi_h12_re),
        .h12_im    (csi_h12_im),
        .h21_re    (csi_h21_re),
        .h21_im    (csi_h21_im),
        .h22_re    (csi_h22_re),
        .h22_im    (csi_h22_im),
        .noise_var (sys_noise_var),
        .mod_order (reg_mod_order),
        .ce_out    (sic_rx_ce_out),
        .s1_re     (sic_s1_re),
        .s1_im     (sic_s1_im),
        .s2_re     (sic_s2_re),
        .s2_im     (sic_s2_im)
    );

    // Multiplex Raw Received Outputs based on Mode
    wire [31:0] rx_mux_s1_re = (current_mode == 1'b0) ? stbc_s1_re : sic_s1_re;
    wire [31:0] rx_mux_s1_im = (current_mode == 1'b0) ? stbc_s1_im : sic_s1_im;
    wire [31:0] rx_mux_s2_re = (current_mode == 1'b0) ? stbc_s2_re : sic_s2_re;
    wire [31:0] rx_mux_s2_im = (current_mode == 1'b0) ? stbc_s2_im : sic_s2_im;

    assign rx_s1_raw_re = rx_mux_s1_re;
    assign rx_s1_raw_im = rx_mux_s1_im;
    assign rx_s2_raw_re = rx_mux_s2_re;
    assign rx_s2_raw_im = rx_mux_s2_im;

    // ========================================================================
    // Subsystem 5: Euclidean Constellation Decision Slicers
    // ========================================================================
    wire        slicer1_ce_out;
    wire [31:0] slicer1_s_hat_re, slicer1_s_hat_im;

    qam_slicer_hw u_slicer_stream1 (
        .clk       (clk),
        .rst       (rst),
        .clk_enable(clk_enable),
        .r_i       (rx_mux_s1_re),
        .r_q       (rx_mux_s1_im),
        .mod_order (reg_mod_order),
        .ce_out    (slicer1_ce_out),
        .s_hat_i   (slicer1_s_hat_re),
        .s_hat_q   (slicer1_s_hat_im)
    );

    wire        slicer2_ce_out;
    wire [31:0] slicer2_s_hat_re, slicer2_s_hat_im;

    qam_slicer_hw u_slicer_stream2 (
        .clk       (clk),
        .rst       (rst),
        .clk_enable(clk_enable),
        .r_i       (rx_mux_s2_re),
        .r_q       (rx_mux_s2_im),
        .mod_order (reg_mod_order),
        .ce_out    (slicer2_ce_out),
        .s_hat_i   (slicer2_s_hat_re),
        .s_hat_q   (slicer2_s_hat_im)
    );

    assign rx_s1_hat_re = slicer1_s_hat_re;
    assign rx_s1_hat_im = slicer1_s_hat_im;
    assign rx_s2_hat_re = slicer2_s_hat_re;
    assign rx_s2_hat_im = slicer2_s_hat_im;

    // Receiver Valid Handshake
    assign rx_out_valid   = (current_mode == 1'b0) ? stbc_rx_ce_out : sic_rx_ce_out;
    assign irq_frame_done = rx_out_valid;

endmodule
