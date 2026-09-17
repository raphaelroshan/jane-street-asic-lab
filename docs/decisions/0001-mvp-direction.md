# ADR 0001: single-engine verified peripheral emulator

Status: Accepted for planning, 2026-09-17.

## Context

The competition asks for a general-purpose protocol emulator and rewards
unique functionality and verification methodology.  Public Tiny Tapeout work
already includes CPUs, basic protocol blocks, pulse generators, and logic
analyzers.  A solo project also needs enough routing and schedule margin to
reach silicon-ready evidence.

## Decision

Build one programmable timed-I/O engine with an independent guardian.  The MVP
acts as a peripheral emulator and fault injector, not a transparent two-sided
bridge.  Its differentiator is certified response timing, generic pin-safety
enforcement, and an honest timestamped trace.

## Alternatives considered

### RP2040 PIO clone

Technically credible but insufficiently differentiated.  It remains useful
prior art for instruction density and FIFO semantics.

### Multiple PIO-style engines

Improves concurrency but multiplies registers, FIFOs, arbitration, formal
state space, and routing pressure.  Deferred until a single engine closes with
large margin.

### Transparent capture/replay interposer

Compelling long-term product, but bidirectional forwarding, two-sided timing,
and host-independent trace depth expand the MVP too far.  Peripheral emulation
demonstrates the core value with fewer pins and states.

### General RISC-V core

Tooling is abundant but timed pin operations become multi-instruction and less
analyzable.  Tiny Tapeout already has numerous small RISC-V designs.

## Consequences

- Protocol concurrency is limited in the MVP.
- Timing analysis and formal proofs remain tractable.
- The design leaves area for a guardian and observability rather than spending
  it on duplicate engines.
- A later FPGA version can add engines and deeper trace memory without changing
  the programming concepts.
