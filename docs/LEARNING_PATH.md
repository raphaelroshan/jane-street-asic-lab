# Learning and development path

Each stage ends with a visible artifact and a question you should be able to
answer without asking the automation.

## Stage 0 — reproduce the baseline (now)

- [ ] Run `make setup`, `make doctor`, and `make test`.
- [ ] Read `src/timing_core.v` beside `test/test.py`.
- [ ] Predict the demo waveform before looking at the assertion.
- [ ] Change one `WAIT` operand and update the expected edge sequence.

You should be able to explain why nonblocking assignments make the new pin
value visible after a rising edge and why `WAIT 2` inserts exactly two idle
edges.

## Stage 1 — transmit a UART frame

- [ ] Calculate cycles per bit for one clock frequency and baud rate.
- [ ] Encode a program that transmits a fixed `0x55` 8N1 frame.
- [ ] Write an independent cocotb UART decoder; do not assert a copied waveform.
- [ ] Record baud-rate error and timing assumptions.

Decision gate: is an 8-bit ISA still useful, or has the exercise shown why the
submission needs 16-bit instructions, shift registers, and a clock divider?

## Stage 2 — write the submission architecture record

Before extending RTL, compare at least:

1. one compact CPU;
2. RP2040-PIO-style state machine;
3. deadline/event scheduler with timestamp capture.

Record instruction width, program size/loading, timing guarantees, pin model,
data movement, and rough area cost. Include hand-worked UART, SPI, and I2C
inner loops.

## Stage 3 — build the real engine

- [ ] Replace the teaching ISA behind tests written from the architecture record.
- [ ] Add shift registers and small FIFOs.
- [ ] Add runtime output enable for open-drain I2C.
- [ ] Add an asynchronous-safe host interface.
- [ ] Add protocol firmware and independent reference models.

## Stage 4 — verification and physical design

- [ ] Formalize FIFO safety and deterministic retirement/pin-write latency.
- [ ] Run constrained-random UART, SPI, and I2C tests.
- [ ] Enable Tiny Tapeout RTL and gate-level CI.
- [ ] Harden early; inspect area, timing, congestion, DRC, and precheck results.
- [ ] Prototype on an FPGA if one is available.

## Automation rule

Automate commands, regression, artifact collection, and mechanical encoding.
Do not automate away the protocol timing math, independent oracle, architecture
record, review of warnings, or explanation of why the design should work.
