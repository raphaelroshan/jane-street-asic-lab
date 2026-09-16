# Lab 1 design: deterministic timing core

## Purpose

This core answers one question: how does a programmable hardware engine turn
instructions into pin transitions on exact clock edges? It is intentionally
too small for the final competition submission.

## Loading

Reset the core while `ui_in[7]` (`load_mode`) is high. After reset, present
program bits on `ui_in[0]`, most-significant bit first, one bit per rising clock
edge. Every eight bits commits one instruction into the next of 16 words.
Drive `load_mode` low to execute from address zero on the next rising edge.

Reset before loading a new program. Instruction memory itself is not reset;
software must load every address it will execute.

## Eight-bit teaching ISA

| Bits 7:6 | Instruction | Remaining fields | Clock behavior |
|---|---|---|---|
| `00` | `SET` | pin `[5:3]`, value `[2]` | Change one output; advance PC |
| `01` | `WAIT` | idle count `[5:0]` | Advance PC; insert N idle clocks |
| `10` | `JUMP` | address `[3:0]` | Replace PC |
| `11` | `WAIT_PIN` | pin `[5:3]`, value `[2]` | Hold PC until input matches |

All non-stalled instructions take one clock. `WAIT N` itself consumes one clock
and adds N idle clocks. `WAIT_PIN` consumes one clock per observation and
advances when the requested level is observed.

## Executable timing example

The program `SET p0,1; WAIT 2; SET p0,0; WAIT 1; JUMP 0` produces these values
after successive execution edges:

```text
edge       1 2 3 4 5 6 7 8 9
output[0]  1 1 1 1 0 0 0 0 1
operation  S W - - S W - J S
```

`test/test.py` checks this exact sequence. If the intended meaning of `WAIT`
changes, update this document first, then the test, then the RTL.

## Deliberate omissions

- no data registers or shifting
- no FIFO
- no clock divider
- no runtime output-enable control
- no robust asynchronous host interface
- no input synchronizers

Those are architecture decisions for later labs, not accidental TODOs.
