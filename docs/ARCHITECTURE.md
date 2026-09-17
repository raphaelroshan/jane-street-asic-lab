# Draft architecture: Verified Protocol Event Engine

Status: **DRAFT — no submission RTL should depend on this until the open
decisions at the end are reviewed.**

## Product statement

Build a general-purpose timed-I/O engine that can emulate peripherals, capture
edge events, and inject reproducible faults after fabrication.  Its distinctive
feature is not protocol count: the engine and its microprograms come with
explicit, machine-checked timing and pin-safety claims.

The primary demonstration is a programmable I2C peripheral emulator that can
return normal register values, inject a selected NACK or delayed ACK, record
what happened, and fail safe if its program misses a deadline.  UART and SPI
programs demonstrate that the silicon is protocol-independent.

## Design principles

1. **Protocols are firmware.** The RTL must not contain UART, SPI, or I2C state
   machines.
2. **One deterministic data plane.** Instructions have fixed latency except for
   explicit, visible waits.
3. **Safety is independent.** A small guardian mediates pin direction and
   watchdog behavior; microcode cannot bypass it.
4. **Claims state assumptions.** Digital proofs begin at synchronized
   `event_seen`, not at an arbitrary asynchronous physical edge.
5. **Observability is a feature.** Overflow, timeout, deadline miss, and policy
   violation are recorded rather than silently hidden.
6. **Area is a requirement.** Synthesis and hardening begin with each major
   block, not after integration.

## Competition MVP

- One programmable execution engine
- 16-bit fixed-width instructions
- Initially 32 x 16-bit writable program memory
- 16-bit system-clock timestamp and deadline registers
- 16-bit input and output shift registers
- Two general scratch registers
- Four-entry 16-bit TX and RX FIFOs
- Eight-entry edge/event trace FIFO, width subject to area measurement
- Four programmable bidirectional protocol pins
- Eight dedicated sample inputs and eight dedicated driven outputs
- Four-pin SPI host interface
- Runtime guardian for pin permissions, open-drain behavior, watchdog expiry,
  FIFO overflow, and missed deadlines
- Firmware examples for UART, SPI, I2C, and one non-obvious use such as edge
  capture or NEC infrared

## Explicit non-goals for the MVP

- Multiple simultaneous execution engines
- A transparent two-sided protocol interposer
- Large on-chip trace memory
- Automatic protocol recognition
- USB or Ethernet
- SRAM macro integration before the flip-flop design has real area numbers
- On-chip formal proof checking
- Cryptographic authentication of programs
- Exact latency promises relative to an asynchronous physical edge

These may be reconsidered only after the MVP passes RTL tests, formal checks,
and a 6x4 hardening run with routing margin.

## Proposed block structure

```text
 ui_in / uio_in
       |
       v
 input synchronizers -----> edge detector -----> trace FIFO
       |                                           |
       v                                           v
 event_seen -------------------------------> host register file
       |                                           ^
       v                                           |
 deterministic engine <---- program RAM <---- host SPI
       |
       v
 requested pin action -----> independent guardian
                                      |
                         +------------+------------+
                         |                         |
                         v                         v
                     uo_out                    uio_out/oe
```

The host plane may be slow and bursty.  The execution and guardian path must
not depend on host progress once a transaction begins.

## Candidate pin map

| Tiny Tapeout pins | Candidate use |
|---|---|
| `ui[7:0]` | Eight programmable sample-only inputs |
| `uo[7:0]` | Eight programmable drive-only outputs |
| `uio[3:0]` | Four programmable bidirectional/open-drain protocol pins |
| `uio[4]` | Host SPI `CS_n` |
| `uio[5]` | Host SPI `SCK` |
| `uio[6]` | Host SPI `MOSI` |
| `uio[7]` | Host SPI `MISO` |

The initial host SPI implementation should be oversampled in the 50 MHz system
clock domain and document a conservative `SCK <= clk/8` limit.  A true
multi-clock implementation is not justified until its CDC and area costs are
measured.

## Logical GPIO model

Microcode sees 20 protocol pins:

- 0–7: sample-only inputs
- 8–15: drive-only outputs, readable as their driven values
- 16–19: bidirectional pins with guardian-mediated output enable

Host SPI pins are not addressable by microcode.  Pin bases may be configurable,
but every instruction also passes through a permission mask in the guardian.

## Execution and timing model

- The engine runs directly from the nominal 50 MHz system clock.
- A normal instruction retires in one clock.
- Delay, input wait, FIFO wait, and deadline wait are explicit states.
- Timing-critical waits have a timeout or a guardian watchdog.
- The 16-bit timestamp increments every system clock and wraps modulo 65536.
- Deadline comparison is wrap-safe only for intervals shorter than 32768 clocks.
- Backward branches in certified programs require a statically bounded loop.
- Firmware may dither adjacent integer periods when a baud rate is not an exact
  divisor of 50 MHz.

The program-analysis tool computes a worst-case path from a synchronized event
to a named checkpoint.  Raw programs may execute for experimentation, but only
programs accepted by the analyzer receive a certificate.  The guardian remains
active in both cases.

## Instruction semantics before encoding

The first ISA design must be driven by UART, SPI, and I2C cycle budgets.  It is
expected to need operations in these semantic groups:

- pin set/output and direction control
- pin sample/input shift
- immediate and register-based deadline updates
- wait for level/edge with timeout
- wait for deadline
- bounded conditional branch and loop
- TX FIFO pull and RX FIFO push
- move/set operations for scratch and shift registers
- trace/event emission

No bit allocation is approved yet.  Encoding the ISA before writing the three
protocol inner loops would turn a learning exercise into guesswork.

## Guardian responsibilities

The guardian is deliberately smaller and simpler than the engine.  It must:

- mask writes to unauthorized pins
- enforce open-drain mode by translating logical high into output-disable
- release protected bidirectional pins no later than one clock after watchdog
  expiry
- reject or flag an output request after a missed deadline
- latch FIFO overflow/underflow and trace overflow
- expose sticky violation bits to the host

The guardian is not a protocol decoder.  Its policies are generic masks,
deadlines, rate limits, and safe output values.

## Area budget

Jane Street currently specifies 6x4 = 24 tiles.  The larger 8x4 possibility is
not part of this plan.

| Block | Initial tile budget |
|---|---:|
| Program storage | 4 |
| Engine registers and datapath | 4 |
| TX/RX and trace FIFOs | 4 |
| Host SPI and input synchronization | 3 |
| Guardian, GPIO merge, status | 2 |
| Clock tree, timing repair, routing margin | 7 |
| **Total** | **24** |

The budgets are stop conditions, not promises.  A block exceeding its budget
must be simplified before another feature is added.  Target no more than about
14K synthesized functional cells until the CMOS5L flow gives better evidence
for the full floorplan.

## Demonstration ladder

1. Fixed UART `0x55` from the teaching core
2. Writable 16-bit program memory and real engine executing the same waveform
3. UART TX/RX through FIFOs
4. SPI controller firmware
5. I2C peripheral firmware with open-drain guardian
6. Selected NACK or delayed-ACK fault injection
7. Timestamped trace exported to VCD/PulseView
8. Identical transaction suite at RTL, gate-level, FPGA, and silicon where
   available

## Open decisions

1. Is 32 instructions sufficient for the I2C peripheral program, or is 64
   required?
2. Does trace storage use 16-bit delta tokens, 20-bit full event records, or a
   small encoder with continuation tokens?
3. Which instruction semantics make all three core protocol loops short while
   keeping static analysis simple?
4. Is host SPI oversampling adequate, or must it become a separate clock domain?
5. Should raw uncertified programs be allowed to drive pins, or only run in a
   guardian-restricted observation mode?
6. What is the smallest useful fault-trigger representation?
