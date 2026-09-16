## How it works

This learning design contains a 16-word, eight-bit instruction memory and a
small deterministic execution engine. A program is shifted into the chip on
`ui_in[0]` while `ui_in[7]` is high. Lowering `ui_in[7]` starts execution at
address zero.

The teaching instruction set can set an output pin, wait an exact number of
clock cycles, jump to an instruction address, or wait until an input pin has a
requested value. It is intentionally smaller than the eventual competition
architecture so that its complete clock-by-clock behavior remains readable.

## How to test

Run `make setup` once and then `make test` from the repository root. The cocotb
tests serially load real programs through the public input pins and check the
output value after each rising clock edge. The same command also runs assembler
unit tests, Verilator lint, and generic Yosys synthesis.

To test manually, hold reset low with `ui_in[7]` high, release reset, and clock
program bytes most-significant bit first on `ui_in[0]`. Lower `ui_in[7]` after
the final byte; execution begins on the next rising clock edge.

## External hardware

No external hardware is required for the learning baseline. An FPGA board may
be added later to exercise protocol timing against physical peripherals.
