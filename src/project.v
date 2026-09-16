/*
 * Copyright (c) 2026 Raphael Roshan
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout wrapper for Lab 1.  The deliberately small timing_core is a
 * learning vehicle, not the final competition architecture.
 */

`default_nettype none

module tt_um_raphaelroshan_protocol_lab (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  timing_core core (
      .clk         (clk),
      .rst_n       (rst_n),
      .load_mode   (ui_in[7]),
      .serial_data (ui_in[0]),
      .sample_in   (ui_in),
      .pin_out     (uo_out)
  );

  // Bidirectional pins are intentionally reserved for a later lab in which
  // you design the host interface and open-drain I2C behavior.
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  wire _unused = &{ena, uio_in, 1'b0};

endmodule

`default_nettype wire
