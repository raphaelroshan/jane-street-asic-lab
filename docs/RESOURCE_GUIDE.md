# Curated resource guide

Read resources when a decision needs them.  Reading everything before making
anything is another form of procrastination.

## Read now: programmable I/O architecture

### RP2040 PIO

- [Official RP2040 datasheet](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf),
  Chapter 3.5
- [Official Raspberry Pi Pico SDK PIO headers and API](https://github.com/raspberrypi/pico-sdk/tree/master/src/rp2_common/hardware_pio/include/hardware)
- [lawrie/fpga_pio](https://github.com/lawrie/fpga_pio), a BSD-licensed FPGA
  recreation useful for examining implementation cost

Focus on why PIO uses 16-bit instructions, 32 shared words, ISR/OSR, FIFOs,
side-set, delay fields, wrap registers, and configurable pin bases.  Ask which
choices improve timing density and which make static analysis harder.

### TI PRU

- [Official TI PRU subsystem overview](https://software-dl.ti.com/processor-sdk-linux/esd/AM64X/latest/exports/docs/common/PRU-ICSS/Overview.html)

Use PRU as the opposite end of the design space: a more conventional real-time
processor with richer software and memory.  Compare flexibility, analyzability,
and area with PIO.

## Read while doing protocol cycle sketches

- [NXP UM10204 I2C-bus specification, Rev. 7.0](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)
- [Corelis SPI tutorial](https://www.corelis.com/education/tutorials/spi-tutorial/)

SPI has no single complete universal compliance specification comparable to
I2C.  After learning CPOL/CPHA conventions, use the actual target device's
datasheet for setup, hold, chip-select, and maximum-frequency requirements.

For UART, begin with the waveform and clock-error model rather than a large
legacy UART register specification.  The project's initial reference behavior
is 8N1 asynchronous serial with explicitly documented baud and sampling rules.

## Read before designing CDC or host SPI

- Clifford Cummings,
  [Clock Domain Crossing (CDC) Design & Verification Techniques Using SystemVerilog](https://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf)
- [VerilogPro CDC series](https://www.verilogpro.com/clock-domain-crossing-part-1/)

Focus on metastability containment, multi-bit coherence, pulse loss, toggle
synchronizers, Gray counters, asynchronous FIFO structure, and why a two-flop
synchronizer does not prove a hard analog latency bound.

The MVP deliberately oversamples host SPI in the system domain.  These
resources help decide when that simplification stops being safe.

## Read before writing formal properties

- [YosysHQ SBY documentation](https://symbiyosys.readthedocs.io/en/latest/)
- [SBY getting started](https://symbiyosys.readthedocs.io/en/latest/quickstart.html)
- ZipCPU, [My first experience with Formal Methods](https://zipcpu.com/blog/2017/10/19/formal-intro.html)
- ZipCPU, [Aggregating verified modules together](https://zipcpu.com/formal/2018/04/23/invariant.html)

Focus on assumptions versus assertions, safety versus liveness, induction,
cover statements, environmental contracts, and vacuity.  Copying assertions
without understanding their assumptions is worse than having fewer proofs.

Useful examples:

- [drewbabel/tinytapeout-uart](https://github.com/drewbabel/tinytapeout-uart)
  combines randomized public-pin tests, gate-level runs, and unbounded UART
  control proofs.
- [meiniKi/logIP](https://github.com/meiniKi/logIP) combines modular analyzer
  testbenches with formal checks.

## Read while building Python/cocotb verification

- [Cocotb documentation](https://docs.cocotb.org/)
- HRT, [How We Verify Custom Hardware](https://www.hudsonrivertrading.com/hrtbeat/verify-custom-hardware/)
- [Hypothesis property-based testing](https://hypothesis.readthedocs.io/)

Focus on independent transaction models, monitors, reproducible random seeds,
portable simulator/lab drivers, and failure minimization.  Do not generate the
RTL and its only oracle from the same description.

## Read during physical-design decisions

- [Tiny Tapeout local hardening guide](https://www.tinytapeout.com/guides/local-hardening/)
- [Tiny Tapeout memory guide](https://tinytapeout.com/specs/memory/)
- [Tiny Tapeout GPIO specifications](https://tinytapeout.com/specs/gpio/)
- [Tiny Tapeout clock guide](https://tinytapeout.com/specs/clock/)
- [IHP SG13CMOS5L open PDK](https://github.com/IHP-GmbH/ihp-sg13cmos5l)
- [LibreLane documentation](https://librelane.readthedocs.io/)

Focus on mapped area versus placed utilization, CTS/hold-repair overhead,
routing layers, PVT corners, pad limits, SRAM integration risk, DRC/LVS, and why
a design that synthesizes can still fail routing.

## Read for evidence quality

- [TinyQV competition winners](https://tinytapeout.com/competitions/risc-v-peripheral-winners/)
- [BF16 FMA](https://github.com/akankaan/bf16-fma)
- [TinyQV](https://github.com/MichaelBell/tinyQV)
- Jane Street, [Programmable Hardware](https://signalsandthreads.com/programmable-hardware/)
- Jane Street, [protocol emulator competition](https://blog.janestreet.com/protocol-emulator-asic-competition/)

Look at how strong projects expose numerical error, instruction timing,
physical limitations, test artifacts, and failed assumptions.  The goal is not
to imitate their functionality; it is to imitate their evidence discipline.

## Useful tools already in this repository

```sh
make setup           # project-local OSS CAD Suite and Python environment
make doctor          # resolve tool paths
make test            # unit tests, RTL cocotb, lint, generic synthesis
make measure-memory  # compare isolated 32x16 and 64x16 program stores
```

The GitHub workflows additionally run Tiny Tapeout documentation, CMOS5L GDS,
precheck, gate-level simulation, and the layout viewer when relevant files
change.
