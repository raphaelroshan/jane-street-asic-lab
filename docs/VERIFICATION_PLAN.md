# Verification plan

Status: **DRAFT — properties precede the submission RTL.**

Verification is a product feature of this project.  Every public performance
or safety claim must identify its assumptions, executable evidence, and the
layer at which it is valid.

## Evidence layers

| Claim type | Required evidence |
|---|---|
| Instruction and guardian semantics | Formal RTL properties |
| Microprogram worst-case cycles | Static control-flow analysis |
| UART/SPI/I2C behavior | Independent Python models and constrained-random tests |
| Synthesized-netlist behavior | The same cocotb suite at gate level |
| Maximum clock frequency | Post-route STA at required PVT corners |
| Physical asynchronous-edge latency | Stated synchronizer assumption plus FPGA/silicon measurement |
| Area and routability | Full Tiny Tapeout hardening, DRC, LVS, congestion reports |

Formal verification must not be described as proving analog metastability,
pad delay, signal integrity, or fabricated maximum frequency.

## Initial formal properties

### P1 — deterministic retirement

For every non-stalling opcode, a valid instruction at cycle `N` retires exactly
once at `N+1`, with the documented next PC and state change.

### P2 — guardian pin safety

For all engine states and programs, a pin outside the active permission mask is
never driven.  In open-drain mode, a logical one never produces output-enable
with output value one.

### P3 — fail-safe watchdog

If the watchdog expires at cycle `N`, all protected bidirectional output-enable
bits are clear by cycle `N+1` and remain clear until an explicit host restart.

### P4 — FIFO integrity

Accepted entries emerge in order, at most once, and unchanged.  Full pushes and
empty pops produce explicit status; they never silently overwrite or invent an
entry.

### P5 — deadline violation visibility

An output request made after its active deadline cannot be silently committed:
it is either blocked or accompanied by a sticky deadline-violation flag in the
same transition.

### P6 — trace honesty

Every accepted trace event corresponds to one real internal event with its
recorded delta.  When storage is exhausted, overflow becomes sticky before any
subsequent event could be mistaken for a complete trace.

P1–P4 are MVP requirements.  P5 and P6 enter once their blocks exist.

## Program certification

The host analyzer consumes assembled microcode and a manifest containing clock
frequency, pin permissions, transaction entry points, deadlines, and input-rate
assumptions.  It builds a control-flow graph and rejects:

- unrestricted backward jumps
- waits without timeouts on a certified response path
- blocking FIFO operations without a bounded environment assumption
- paths that access unauthorized pins
- paths whose worst-case cycle count exceeds a declared deadline
- loops whose maximum trip count cannot be derived statically

The report is tied to the exact program bytes by a host-side digest.  The MVP
does not put a cryptographic proof checker on-chip.  Runtime safety comes from
the independent guardian and watchdog.

## Protocol test strategy

Each protocol suite communicates through public top-level pins and the real
host interface.  Reference models must not import the assembler's execution
model or duplicate the RTL algorithm.

### UART

- randomized bytes and payload lengths
- several baud rates and integer-period dithering
- framing error, early start glitch, and clock mismatch
- TX and RX FIFO pressure

### SPI

- modes 0–3
- randomized words, lengths, and idle gaps
- MISO/MOSI edge alignment
- chip-select interruption and restart

### I2C

- start, repeated start, stop, ACK, and NACK
- standard and fast-mode timing budgets where I/O permits
- clock stretching and timeout
- open-drain direction checks
- register-map side effects
- selected delayed ACK and injected NACK

Every randomized failure records its seed.  Important boundary cases also
exist as named directed tests so regressions remain understandable.

## Anti-vacuity requirements

A formal run counts only when:

- reset is reached and meaningful operation is covered
- each antecedent can be covered
- a deliberately broken version of the relevant behavior fails the property
- assumptions are listed in the report
- bounded proofs are labeled bounded; induction claims record their depth and
  engine

## AI-assisted verification policy

AI may propose properties, generate boundary cases, minimize failing traces,
and summarize reports.  It may not be the sole source of both RTL behavior and
its oracle.  Protocol expectations come from independent specifications or
reference implementations, and a human reviews every assumption used by a
proof.

## Definition of verified

A feature is not "verified" merely because its RTL test passes.  MVP sign-off
requires:

1. named directed tests;
2. constrained-random tests with reproducible seeds;
3. applicable formal properties;
4. RTL and gate-level execution of the public-pin suite;
5. clean synthesis/lint;
6. a routed design with DRC/LVS and timing evidence;
7. a concise limitations section.
