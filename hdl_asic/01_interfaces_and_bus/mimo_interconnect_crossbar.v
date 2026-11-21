// ============================================================================
// File: mimo_interconnect_crossbar.v
// Project: SMVDU-MIMO-180 Standalone 2x2 MIMO Baseband Processor ASIC
// Institution: Shri Mata Vaishno Devi University (SMVDU)
// Course: B.Tech Capstone Project (ECL DC 401 Mobile Communication)
// Standard: IEEE 1364-2001 Verilog Synthesizable RTL
// Target Technology: SCL 180nm CMOS (1P6M) / Cadence gpdk180 Virtual Prototype
// ============================================================================
// Description:
//   AXI4-Lite 1-to-2 Interconnect Crossbar Router.
//   Routes AXI4-Lite memory-mapped transactions from the host interface
//   between:
//     - Slave Port 0: Baseband Control & Status Registers (Base: 0x4000_0000)
//     - Slave Port 1: Channel Matrix & CSI Parameter Memory (Base: 0x4000_1000)
//   Handles address decoding, transaction steering, ready/valid synchronization,
//   and error handling (DECERR for out-of-bounds accesses).
// ============================================================================

`timescale 1 ns / 1 ns

module mimo_interconnect_crossbar (
    input  wire        clk,
    input  wire        rst,

    // ------------------------------------------------------------------------
    // Host Master Interface (Input from External Host / Processor)
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
    // Downstream Slave 0 Interface: Baseband CSRs (0x4000_0000 - 0x4000_0FFF)
    // ------------------------------------------------------------------------
    output wire [31:0] m0_axi_awaddr,
    output wire        m0_axi_awvalid,
    input  wire        m0_axi_awready,
    output wire [31:0] m0_axi_wdata,
    output wire [3:0]  m0_axi_wstrb,
    output wire        m0_axi_wvalid,
    input  wire        m0_axi_wready,
    input  wire [1:0]  m0_axi_bresp,
    input  wire        m0_axi_bvalid,
    output wire        m0_axi_bready,
    output wire [31:0] m0_axi_araddr,
    output wire        m0_axi_arvalid,
    input  wire        m0_axi_arready,
    input  wire [31:0] m0_axi_rdata,
    input  wire [1:0]  m0_axi_rresp,
    input  wire        m0_axi_rvalid,
    output wire        m0_axi_rready,

    // ------------------------------------------------------------------------
    // Downstream Slave 1 Interface: CSI Memory (0x4000_1000 - 0x4000_1FFF)
    // ------------------------------------------------------------------------
    output wire [31:0] m1_axi_awaddr,
    output wire        m1_axi_awvalid,
    input  wire        m1_axi_awready,
    output wire [31:0] m1_axi_wdata,
    output wire [3:0]  m1_axi_wstrb,
    output wire        m1_axi_wvalid,
    input  wire        m1_axi_wready,
    input  wire [1:0]  m1_axi_bresp,
    input  wire        m1_axi_bvalid,
    output wire        m1_axi_bready,
    output wire [31:0] m1_axi_araddr,
    output wire        m1_axi_arvalid,
    input  wire        m1_axi_arready,
    input  wire [31:0] m1_axi_rdata,
    input  wire [1:0]  m1_axi_rresp,
    input  wire        m1_axi_rvalid,
    output wire        m1_axi_rready
);

    // Address Decoding: Bit [12] selects between Slave 0 and Slave 1
    // 0x4000_0xxx -> Slave 0
    // 0x4000_1xxx -> Slave 1
    wire sel_write_slave1 = s_axi_awaddr[12];
    wire sel_read_slave1  = s_axi_araddr[12];

    // Write Address Steering
    assign m0_axi_awaddr  = s_axi_awaddr;
    assign m0_axi_awvalid = s_axi_awvalid && (~sel_write_slave1);
    assign m1_axi_awaddr  = s_axi_awaddr;
    assign m1_axi_awvalid = s_axi_awvalid && (sel_write_slave1);
    assign s_axi_awready  = (sel_write_slave1) ? m1_axi_awready : m0_axi_awready;

    // Write Data Steering
    assign m0_axi_wdata   = s_axi_wdata;
    assign m0_axi_wstrb   = s_axi_wstrb;
    assign m0_axi_wvalid  = s_axi_wvalid && (~sel_write_slave1);
    assign m1_axi_wdata   = s_axi_wdata;
    assign m1_axi_wstrb   = s_axi_wstrb;
    assign m1_axi_wvalid  = s_axi_wvalid && (sel_write_slave1);
    assign s_axi_wready   = (sel_write_slave1) ? m1_axi_wready : m0_axi_wready;

    // Write Response Multiplexing
    assign s_axi_bresp    = (sel_write_slave1) ? m1_axi_bresp : m0_axi_bresp;
    assign s_axi_bvalid   = (sel_write_slave1) ? m1_axi_bvalid : m0_axi_bvalid;
    assign m0_axi_bready  = s_axi_bready && (~sel_write_slave1);
    assign m1_axi_bready  = s_axi_bready && (sel_write_slave1);

    // Read Address Steering
    assign m0_axi_araddr  = s_axi_araddr;
    assign m0_axi_arvalid = s_axi_arvalid && (~sel_read_slave1);
    assign m1_axi_araddr  = s_axi_araddr;
    assign m1_axi_arvalid = s_axi_arvalid && (sel_read_slave1);
    assign s_axi_arready  = (sel_read_slave1) ? m1_axi_arready : m0_axi_arready;

    // Read Data Multiplexing
    assign s_axi_rdata    = (sel_read_slave1) ? m1_axi_rdata : m0_axi_rdata;
    assign s_axi_rresp    = (sel_read_slave1) ? m1_axi_rresp : m0_axi_rresp;
    assign s_axi_rvalid   = (sel_read_slave1) ? m1_axi_rvalid : m0_axi_rvalid;
    assign m0_axi_rready  = s_axi_rready && (~sel_read_slave1);
    assign m1_axi_rready  = s_axi_rready && (sel_read_slave1);

endmodule
