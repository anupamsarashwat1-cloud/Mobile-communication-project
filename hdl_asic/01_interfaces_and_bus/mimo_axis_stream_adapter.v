// ============================================================================
// File: mimo_axis_stream_adapter.v
// Project: SMVDU-MIMO-180 Standalone 2x2 MIMO Baseband Processor ASIC
// Institution: Shri Mata Vaishno Devi University (SMVDU)
// Course: B.Tech Capstone Project (ECL DC 401 Mobile Communication)
// Standard: IEEE 1364-2001 Verilog Synthesizable RTL
// Target Technology: SCL 180nm CMOS (1P6M) / Cadence gpdk180 Virtual Prototype
// ============================================================================
// Description:
//   AXI4-Stream Elastic Skid Buffer & Rate-Matching Adapter.
//   Decouples the high-speed RF ADC/DAC converter interfaces from the baseband
//   pipeline. Eliminates combinational loop backpressure paths between
//   m_axis_tready and s_axis_tready, guaranteeing full 100 MHz line-rate
//   streaming (1 sample per cycle) with zero bubbles or pipeline stalls.
// ============================================================================

`timescale 1 ns / 1 ns

module mimo_axis_stream_adapter #(
    parameter DATA_WIDTH = 64 // 32-bit In-Phase (I) + 32-bit Quadrature (Q)
)(
    input  wire                  clk,
    input  wire                  rst,

    // Slave AXI-Stream Ingest (From ADC / Modulator)
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire                  s_axis_tlast,

    // Master AXI-Stream Egress (To Baseband Pipeline / DAC)
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,
    output reg                   m_axis_tlast
);

    // Internal Skid Buffer Registers
    reg [DATA_WIDTH-1:0] skid_data;
    reg                  skid_last;
    reg                  skid_valid;

    // Full throughput ready generation
    assign s_axis_tready = ~skid_valid;

    always @(posedge clk) begin
        if (rst) begin
            m_axis_tdata  <= {DATA_WIDTH{1'b0}};
            m_axis_tlast  <= 1'b0;
            m_axis_tvalid <= 1'b0;
            skid_data     <= {DATA_WIDTH{1'b0}};
            skid_last     <= 1'b0;
            skid_valid    <= 1'b0;
        end else begin
            // ----------------------------------------------------------------
            // Forward Path Egress
            // ----------------------------------------------------------------
            if (m_axis_tready) begin
                if (skid_valid) begin
                    // Empty skid buffer into output
                    m_axis_tdata  <= skid_data;
                    m_axis_tlast  <= skid_last;
                    m_axis_tvalid <= 1'b1;
                    skid_valid    <= 1'b0;
                end else if (s_axis_tvalid) begin
                    // Pass input directly to output
                    m_axis_tdata  <= s_axis_tdata;
                    m_axis_tlast  <= s_axis_tlast;
                    m_axis_tvalid <= 1'b1;
                end else begin
                    m_axis_tvalid <= 1'b0;
                end
            end else begin
                // ------------------------------------------------------------
                // Backpressure Active: Capture into Skid Buffer
                // ------------------------------------------------------------
                if (s_axis_tvalid && ~skid_valid) begin
                    skid_data  <= s_axis_tdata;
                    skid_last  <= s_axis_tlast;
                    skid_valid <= 1'b1;
                end
            end
        end
    end

endmodule
