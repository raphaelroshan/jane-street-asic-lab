/*
 * Measurement-only asynchronous-read program store.
 *
 * This is not submission RTL.  It isolates the cost of the simplest memory
 * semantics the teaching core currently uses: one synchronous write port and
 * one combinational read port.
 */

`default_nettype none

module program_store #(
    parameter integer WORDS = 32,
    parameter integer ADDR_WIDTH = 5
) (
    input  wire                  clk,
    input  wire                  write_enable,
    input  wire [ADDR_WIDTH-1:0] write_address,
    input  wire [15:0]           write_data,
    input  wire [ADDR_WIDTH-1:0] read_address,
    output wire [15:0]           read_data
);

  reg [15:0] words [0:WORDS-1];

  always @(posedge clk) begin
    if (write_enable) begin
      words[write_address] <= write_data;
    end
  end

  assign read_data = words[read_address];

endmodule

`default_nettype wire
