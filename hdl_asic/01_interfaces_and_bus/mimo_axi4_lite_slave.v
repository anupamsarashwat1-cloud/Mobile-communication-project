// ============================================================================
// File: mimo_axi4_lite_slave.v
// Project: SMVDU-MIMO-180 Standalone 2x2 MIMO Baseband Processor ASIC
// Institution: Shri Mata Vaishno Devi University (SMVDU)
// Course: B.Tech Capstone Project (ECL DC 401 Mobile Communication)
// Standard: IEEE 1364-2001 Verilog Synthesizable RTL
// Target Technology: SCL 180nm CMOS (1P6M) / Cadence gpdk180 Virtual Prototype
// ============================================================================
// Description:
//   Standard 32-bit AXI4-Lite Slave Register File for SMVDU-MIMO-180 ASIC.
//   Provides memory-mapped register access for:
//     - Core run/stop control and soft pipeline reset
//     - Manual mode override controls (forced STBC vs Spatial Multiplexing)
//     - IEEE-754 Single-Precision condition number & SNR switching thresholds
//     - Total power budget and modulation order settings
//     - Real-time telemetry monitoring (allocated power, status, cycle counters)
// ============================================================================

`timescale 1 ns / 1 ns

module mimo_axi4_lite_slave #(
    parameter [31:0] DEFAULT_KAPPA_THRESH = 32'h4090_0000, // 4.5f
    parameter [31:0] DEFAULT_SNR_THRESH   = 32'h40CA_3D71, // 6.30957f (8.0 dB)
    parameter [31:0] DEFAULT_P_TOTAL      = 32'h3F80_0000, // 1.0f
    parameter [31:0] DEFAULT_MOD_ORDER    = 32'h4080_0000  // 4.0f (QPSK)
)(
    // Clock and Reset
    input  wire        clk,
    input  wire        rst, // Synchronous Active-High Reset

    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    // Control Outputs to Baseband Core
    output wire        reg_core_enable,
    output wire        reg_mode_override_en,
    output wire        reg_mode_override_val,
    output wire        reg_soft_reset,
    output wire [31:0] reg_kappa_thresh,
    output wire [31:0] reg_snr_thresh,
    output wire [31:0] reg_total_power,
    output wire [31:0] reg_mod_order,

    // Telemetry & Status Inputs from Baseband Core
    input  wire        status_core_ready,
    input  wire        status_active_mode,
    input  wire        status_kappa_is_high,
    input  wire [1:0]  status_active_rank,
    input  wire [31:0] telemetry_p1_power,
    input  wire [31:0] telemetry_p2_power,
    input  wire        event_frame_done
);

    // Constant Response
    assign s_axi_bresp = 2'b00; // OKAY
    assign s_axi_rresp = 2'b00; // OKAY

    // Internal Register Declarations
    reg [31:0] r_control;
    reg [31:0] r_kappa_thresh;
    reg [31:0] r_snr_thresh;
    reg [31:0] r_total_power;
    reg [31:0] r_mod_order;
    reg [31:0] r_cycle_count;
    reg [31:0] r_frame_count;

    // Control output decoding
    assign reg_core_enable       = r_control[0];
    assign reg_mode_override_en  = r_control[1];
    assign reg_mode_override_val = r_control[2];
    assign reg_soft_reset        = r_control[3];
    assign reg_kappa_thresh      = r_kappa_thresh;
    assign reg_snr_thresh        = r_snr_thresh;
    assign reg_total_power       = r_total_power;
    assign reg_mod_order         = r_mod_order;

    // ------------------------------------------------------------------------
    // AXI4-Lite Write Transaction State Machine & Register Update
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            r_control      <= 32'h0000_0001; // Core enabled by default
            r_kappa_thresh <= DEFAULT_KAPPA_THRESH;
            r_snr_thresh   <= DEFAULT_SNR_THRESH;
            r_total_power  <= DEFAULT_P_TOTAL;
            r_mod_order    <= DEFAULT_MOD_ORDER;
        end else begin
            // Address Write Handshake
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Data Write Handshake
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Register Write Execution
            if (s_axi_awvalid && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                case (s_axi_awaddr[5:0])
                    6'h00: begin
                        if (s_axi_wstrb[0]) r_control[7:0]   <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) r_control[15:8]  <= s_axi_wdata[15:8];
                        if (s_axi_wstrb[2]) r_control[23:16] <= s_axi_wdata[23:16];
                        if (s_axi_wstrb[3]) r_control[31:24] <= s_axi_wdata[31:24];
                    end
                    6'h08: r_kappa_thresh <= s_axi_wdata;
                    6'h0C: r_snr_thresh   <= s_axi_wdata;
                    6'h10: r_total_power  <= s_axi_wdata;
                    6'h14: r_mod_order    <= s_axi_wdata;
                    default: ;
                endcase
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // AXI4-Lite Read Transaction State Machine
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'd0;
        end else begin
            // Address Read Handshake
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Data Read Execution
            if (s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[5:0])
                    6'h00: s_axi_rdata <= r_control;
                    6'h04: s_axi_rdata <= {27'd0, status_active_rank, status_kappa_is_high, status_active_mode, status_core_ready};
                    6'h08: s_axi_rdata <= r_kappa_thresh;
                    6'h0C: s_axi_rdata <= r_snr_thresh;
                    6'h10: s_axi_rdata <= r_total_power;
                    6'h14: s_axi_rdata <= r_mod_order;
                    6'h18: s_axi_rdata <= telemetry_p1_power;
                    6'h1C: s_axi_rdata <= telemetry_p2_power;
                    6'h20: s_axi_rdata <= r_cycle_count;
                    6'h24: s_axi_rdata <= r_frame_count;
                    default: s_axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end else if (s_axi_rready && s_axi_rvalid) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Diagnostic Counters (Cycle and Frame Counters)
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst || reg_soft_reset) begin
            r_cycle_count <= 32'd0;
            r_frame_count <= 32'd0;
        end else begin
            r_cycle_count <= r_cycle_count + 1'b1;
            if (event_frame_done) begin
                r_frame_count <= r_frame_count + 1'b1;
            end
        end
    end

endmodule
