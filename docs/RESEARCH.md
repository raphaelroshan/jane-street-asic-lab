# Public research informing the project direction

This project does not attempt to infer proprietary trading systems.  It uses
public engineering material to identify transferable design patterns and maps
them to a Tiny Tapeout-sized hardware tool.

## Jane Street signals

The [protocol-emulator competition](https://blog.janestreet.com/protocol-emulator-asic-competition/)
explicitly asks for post-fabrication programmability, useful debugging and
reverse-engineering behavior, and novel verification methods including formal,
constrained-random, and AI-assisted verification.

In the [Programmable Hardware](https://signalsandthreads.com/programmable-hardware/)
conversation, Jane Street's hardware lead emphasizes customized streaming
architectures, low and predictable latency, and applying software-engineering
lessons to hardware development.  The discussion distinguishes hardware's
cycle-level predictability from software tail latency while acknowledging
clock-domain and memory sources of nondeterminism.

Jane Street has also hosted work on
[verifying programmable network data planes](https://blog.janestreet.com/jane-street-tech-talk-verifying-network-data-planes/),
and its public hardware role stresses tools that make hardware programming,
testing, and validation faster and more reliable.

Project implications:

- optimize for deterministic, explainable event processing rather than a high
  headline clock
- make the programming and verification toolchain part of the design
- state clock-domain assumptions rather than hiding them
- demonstrate flexibility with firmware loaded into one fixed netlist

## HRT signals

HRT's public article
[How We Verify Custom Hardware](https://www.hudsonrivertrading.com/hrtbeat/verify-custom-hardware/)
describes several goals relevant here:

- functional correctness includes independent risk checks and external rules
- developer productivity and time-to-market matter
- C++/Python logic should be reused in verification where appropriate
- cocotb and Verilator enable expressive, scalable co-simulation
- randomized tests should run frequently in CI
- the same tests should be portable from simulation to real FPGA hardware

HRT's public tooling work, including its
[SystemVerilog language server](https://www.hudsonrivertrading.com/hrtbeat/designing-a-systemverilog-language-server/),
also shows the value of fast feedback, open tooling, simulator portability, and
treating hardware as part of a modern software-development environment.

Project implications:

- use independent Python protocol models through public pins
- keep tests portable across RTL, gates, FPGA, and eventual silicon
- separate programmable behavior from an independent fail-safe guardian
- make every randomized failure reproducible by seed
- invest in one-command evidence and understandable failure traces

## Tiny Tapeout signals

The [silicon-proven catalog](https://tinytapeout.com/chips/silicon-proven/)
contains many CPUs, basic serial peripherals, visual/audio projects, and fixed
accelerators.  A metadata scan of 2,575 indexed entries across fourteen
shuttles found debugging/capture terminology in only a small fraction.  This is
a directional observation, not a rigorous taxonomy: descriptions are
inconsistent and some designs are resubmitted.

The prior
[TinyQV peripheral competition](https://tinytapeout.com/competitions/risc-v-peripheral-winners/)
awarded explicit Best Tested and Best Documentation categories.  Its CORDIC
winner used broad numerical sweeps, independent numerical references,
invariants, plots, and retained artifacts.  Other winners exercised extensive
invalid and boundary cases.

Notable public examples:

- [BF16 FMA](https://github.com/akankaan/bf16-fma) combines an exact reference
  model, large randomized campaigns, targeted formal checks, FPGA tests, and
  detailed PVT/physical evidence.
- [logIP](https://github.com/meiniKi/logIP) demonstrates that a plain logic
  analyzer is not unique; it already combines modular simulation, formal work,
  and standard SUMP/PulseView integration.
- [TinyQV](https://github.com/MichaelBell/tinyQV) documents instruction timing,
  area-conscious architectural tradeoffs, and FPGA validation.

Project implications:

- do not compete as another CPU, fixed UART/SPI/I2C block, or basic analyzer
- combine programmable emulation, deterministic fault injection, and honest
  trace capture
- make program timing/safety certification a user-facing capability
- retain judge-readable evidence rather than only pass/fail badges

## Chosen transferable pattern

The project models a generic trustworthy streaming data plane:

```text
event input -> classify -> safety policy -> scheduled action -> trace/status
```

This is demonstrated on UART, SPI, and I2C because they fit the process and I/O
budget.  It is not presented as a production trading datapath.  The value is in
the reusable pattern: deterministic execution, independent safety enforcement,
replayable evidence, and a disciplined verification workflow.
