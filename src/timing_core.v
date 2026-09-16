/*
 * Copyright (c) 2026 Raphael Roshan
 * SPDX-License-Identifier: Apache-2.0
 *
 * Lab 1: an intentionally tiny, deterministic timing engine.
 *
 * This is disposable teaching RTL.  Its purpose is to make instruction
 * timing, program loading, and verification visible before a submission ISA
 * is designed.  See docs/DESIGN.md before extending it.
 */

`default_nettype none

module timing_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load_mode,
    input  wire       serial_data,
    input  wire [7:0] sample_in,
    output reg  [7:0] pin_out
);

  localparam [1:0] OP_SET      = 2'b00;
  localparam [1:0] OP_WAIT     = 2'b01;
  localparam [1:0] OP_JUMP     = 2'b10;
  localparam [1:0] OP_WAIT_PIN = 2'b11;

  reg [7:0] instruction_memory [0:15];
  reg [3:0] program_counter;
  reg [5:0] delay_remaining;

  reg [6:0] load_shift;
  reg [2:0] load_bit_index;
  reg [3:0] load_address;

  wire [7:0] instruction = instruction_memory[program_counter];
  wire [1:0] opcode = instruction[7:6];
  wire [2:0] selected_pin = instruction[5:3];

  always @(posedge clk) begin
    if (!rst_n) begin
      pin_out         <= 8'b0;
      program_counter <= 4'b0;
      delay_remaining <= 6'b0;
      load_shift      <= 7'b0;
      load_bit_index  <= 3'b0;
      load_address    <= 4'b0;
    end else if (load_mode) begin
      // Programs are shifted most-significant bit first.  Reset before each
      // load; instruction memory is intentionally not reset to avoid wasting
      // gates on a behavior the loader already provides.
      pin_out         <= 8'b0;
      program_counter <= 4'b0;
      delay_remaining <= 6'b0;
      load_shift      <= {load_shift[5:0], serial_data};

      if (load_bit_index == 3'd7) begin
        instruction_memory[load_address] <= {load_shift, serial_data};
        load_address   <= load_address + 1'b1;
        load_bit_index <= 3'b0;
      end else begin
        load_bit_index <= load_bit_index + 1'b1;
      end
    end else if (delay_remaining != 0) begin
      delay_remaining <= delay_remaining - 1'b1;
    end else begin
      case (opcode)
        OP_SET: begin
          pin_out[selected_pin] <= instruction[2];
          program_counter       <= program_counter + 1'b1;
        end

        OP_WAIT: begin
          // WAIT N retires now and then inserts N idle clock cycles.
          delay_remaining <= instruction[5:0];
          program_counter <= program_counter + 1'b1;
        end

        OP_JUMP: begin
          program_counter <= instruction[3:0];
        end

        OP_WAIT_PIN: begin
          // Retire only when the selected input has the requested value.
          if (sample_in[selected_pin] == instruction[2]) begin
            program_counter <= program_counter + 1'b1;
          end
        end
      endcase
    end
  end

endmodule

`default_nettype wire
