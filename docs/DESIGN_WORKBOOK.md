# Design decision workbook

This is the recommended order for learning and deciding.  Do not answer every
question from intuition.  Time-box reading, predict a result, run the smallest
experiment that distinguishes the alternatives, and record the consequence.

Use [`decisions/TEMPLATE.md`](decisions/TEMPLATE.md) for decisions that affect
interfaces, timing semantics, program compatibility, or physical area.

## Working rule

For each decision:

1. Write what you currently believe before reading implementations.
2. Identify two credible alternatives.
3. State what evidence would change your mind.
4. Run one focused experiment or calculation.
5. Record the choice and what becomes harder because of it.
6. Add a revisit trigger rather than keeping the choice permanently vague.

## D0 — What exact user problem wins the demo?

Time-box: 2 hours.

Questions:

- Is the headline product a peripheral emulator, temporal monitor, fault
  injector, or capture/replay tool?
- Who is holding the dev board and what problem do they solve in five minutes?
- What capability cannot be replicated by a fixed UART/I2C/SPI peripheral?
- What is the single judge-visible moment that demonstrates flexibility?
- Which feature would still be useful if the competition did not exist?

Exercise:

Write a six-step demonstration with one controller, one emulated device, one
fault, and one evidence report.  No step may say “configure as appropriate.”

Decision artifact:

One paragraph in `ARCHITECTURE.md`, plus explicit MVP/non-goal lists.

Current hypothesis:

An I2C virtual sensor runs normally, injects a selected NACK or delayed ACK,
records the event, and proves bounded post-synchronization response and safe
open-drain behavior.

## D1 — What does “bounded latency” mean?

Time-box: 4 hours.

Questions:

- Does the bound begin at a physical edge, synchronized `event_seen`, decoded
  transaction, or instruction dispatch?
- Which latency is exact, which is a range, and which is only measured?
- What happens when a deadline is missed: late output, blocked output, halt, or
  safe release?
- How does 16-bit timestamp wrap work?
- Which environment assumptions are acceptable and observable?

Exercise:

Draw a clock-edge timeline for an asynchronous SDA transition passing through
two synchronizer flops, program dispatch, guardian approval, output register,
and pad.  Mark what RTL formal can and cannot prove.

Decision artifact:

ADR 0002 plus assertion-ready definitions of `event_seen`, `retire`,
`deadline_miss`, and `pin_commit`.

Revisit trigger:

FPGA or silicon measurements show synchronizer/pad behavior outside the stated
physical timing envelope.

## D2 — What protocol performance is actually required?

Time-box: 3 hours; initial draft completed.

Questions:

- Is 5 MHz SPI enough for the product story, or is 10 MHz materially better?
- Which UART rates must be demonstrated?
- Is I2C peripheral role sufficient, or must controller role be MVP?
- What timeout is acceptable for clock stretching?
- Which protocol behavior forces the most demanding instruction sequence?

Exercise:

Recalculate every table in `CYCLE_BUDGETS.md` independently.  Then write
pseudo-assembly for one bit of UART TX/RX, all four SPI phases, and I2C ACK.

Decision artifact:

Pinned protocol targets and maximum active instructions per bit/phase.

## D3 — How are pins and the host separated?

Time-box: 4 hours; candidate contract drafted.

Questions:

- Are four bidirectional protocol pins sufficient for the demo and future
  firmware?
- Is dedicating four `uio` pins to host SPI worth losing them to microcode?
- Can an oversampled SPI target meet external MISO timing at `clk/8`?
- What happens on an aborted or malformed host frame?
- Can the host modify live state, or only disabled state?

Exercise:

Implement only the SPI synchronizers and 24-bit frame counter in a test module.
Randomize phase between system clock and SCK, sweep SCK rate, abort at every bit
position, and inspect the MISO setup margin.

Decision artifact:

`HOST_INTERFACE.md`, a timing diagram, and passing abort/CDC tests.

## D4 — How much state can the area afford?

Time-box: 1–2 days because physical runs are slow.

Questions:

- Does each protocol fit in 32 instructions?
- Is 64-word flexibility worth roughly twice the storage and mux logic?
- Should read memory be asynchronous for one-cycle fetch or synchronous with a
  fetch pipeline?
- How deep must TX, RX, and trace FIFOs be for the actual demos?
- Which data should stream to the host instead of remaining on-chip?

Exercise:

Assemble realistic pseudo-programs, then harden isolated 32x16 and 64x16 stores
in CMOS5L.  Compare cells, sequential area, timing repair, clock buffers,
critical path, congestion, and route completion.

Current evidence:

The generic experiment reports 1,418 cells for 32x16 and 2,841 for 64x16.
This is not sufficient for a final decision.

Decision artifact:

ADR selecting depth/read semantics and an updated 24-tile budget.

## D5 — What are the minimum instruction semantics?

Time-box: 8–12 hours after D2 and D4.

Questions:

- Which operations must combine to meet SPI timing?
- Is side-set worth its encoding and mux cost?
- Do we need X/Y only, or a four-register file?
- How are ISR/OSR counts represented?
- Are loop bounds encoded, configured, or inferred by the analyzer?
- Which operations may stall, and what makes each stall bounded?
- Does firmware need ALU operations beyond decrement, compare, invert, and
  shift?

Exercise:

Write complete symbolic programs—not RTL—for UART TX/RX, SPI mode 0 and mode 3,
and an I2C register read.  Count words and cycles.  Remove one proposed opcode
at a time and observe which programs become unacceptable.

Decision artifact:

A 16-bit encoding table with exact cycle semantics, examples, rejected
alternatives, and assembler round-trip tests written before engine RTL.

## D6 — What does the guardian enforce independently?

Time-box: 4–6 hours.

Questions:

- Which failure must remain safe even if microcode is arbitrary?
- Is a missed deadline blocked or merely flagged?
- What is the safe value/direction for every pin class?
- Does watchdog expiry halt execution or allow a host-configured recovery PC?
- Are rate limits needed for MVP, or only permission/open-drain/deadline checks?

Exercise:

Write a malicious-program table: unauthorized drive, actively driving I2C high,
infinite loop, output after deadline, FIFO abuse, and host reconfiguration while
running.  Specify the visible and pin-level result of each.

Decision artifact:

Guardian transition table and formal properties P2, P3, and P5.

## D7 — What trace format provides real value per bit?

Time-box: 4 hours plus a small software prototype.

Questions:

- Do we trace physical pin edges, synchronized edges, program actions, guardian
  decisions, or all four with event types?
- How many bits are spent on delta time versus pin/event identity?
- How is a long quiet period represented?
- What does overflow mean, and can a consumer detect an incomplete trace?
- Is eight entries enough when streaming continuously to host SPI?

Exercise:

Capture representative UART, SPI, and I2C traces in Python.  Encode them using
candidate 16-bit token formats and compare token counts and ambiguity.

Decision artifact:

Trace token specification, overflow semantics, and a VCD round-trip test.

## D8 — What makes a program “certified”?

Time-box: 8 hours for the model, implementation later.

Questions:

- Which backward branches are statically acceptable?
- How are dynamic loop counts constrained by a manifest?
- Are waits excluded from response paths, or bounded by timeout?
- How are FIFO arrival-rate assumptions expressed?
- What program bytes and configuration does the certificate digest cover?
- Can raw programs drive pins, or only observe unless guardian limits are set?

Exercise:

Build control-flow graphs for three small programs: one provably bounded, one
with an input wait before its response checkpoint, and one with an unbounded
loop.  Calculate the longest path and explain the rejection reason.

Decision artifact:

Manifest schema and one human-checkable example certificate.

## D9 — How will we know the proofs are meaningful?

Time-box: ongoing; initial policy already drafted.

Questions:

- What assumptions could make each property vacuous?
- How do we cover the antecedent and meaningful operation?
- Which injected bug should make each proof fail?
- Which properties need induction versus bounded exploration?
- Can the same public-pin test run at RTL, gates, FPGA, and silicon?

Exercise:

For P1–P4, write the smallest intentional bug each property must catch.  Do not
count a property complete until the mutation fails.

Decision artifact:

Formal harness, assumption report, cover traces, mutation results, and retained
tool versions.

## D10 — What is the physical stop condition?

Time-box: update after every material block.

Questions:

- What functional-cell ceiling preserves clock/routing margin?
- Which block owns each tile budget?
- How many timing-repair and clock buffers does each state increase create?
- Does 50 MHz close at all required PVT corners?
- When does an SRAM macro become less risky than flip-flop storage?

Exercise:

Maintain a table per hardening run: commit, block set, synthesized cells,
sequential cells, placed cells, utilization, repair buffers, worst setup/hold,
DRC, LVS, and runtime.

Decision artifact:

Updated `STATUS.md` and an explicit simplify-or-continue call after every run.

## D11 — What evidence will a judge see first?

Time-box: decide early, polish late.

Questions:

- Can the demo be understood without reading RTL?
- Is the verification claim visible as a useful capability rather than process
  theater?
- What limitation will a skeptical reviewer ask about first?
- Can one command reproduce the evidence summary?

Exercise:

Draft the final one-page report now with empty measurements.  If a planned
feature does not improve that report or the demo, reconsider its priority.

Decision artifact:

Demo script, evidence matrix, limitations, and reproducible command.

## Suggested first week

1. Recalculate `CYCLE_BUDGETS.md` without looking at its answers.
2. Read the RP2040 PIO chapter and list three choices we should copy and three
   we should reject.
3. Sketch complete UART TX and SPI mode-0 programs using semantic operations.
4. Run `make measure-memory` and explain why asynchronous read creates both
   flops and muxes.
5. Draw the host SPI synchronization timeline.
6. Write a draft malicious-program table for the guardian.
7. Record conclusions in issue comments or a decision record—not private notes.
