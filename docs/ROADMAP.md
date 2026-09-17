# Roadmap to the January 18, 2027 submission

This roadmap assumes one primary contributor using AI for mechanical work and
review support, with architecture, timing math, and evidence interpretation
remaining human-owned.  Scope is reduced before dates move.

## GitHub tracking

- M0: [cycle budgets](https://github.com/raphaelroshan/jane-street-asic-lab/issues/1),
  [memory sizing](https://github.com/raphaelroshan/jane-street-asic-lab/issues/2),
  [ISA freeze](https://github.com/raphaelroshan/jane-street-asic-lab/issues/3),
  [pin/host contract](https://github.com/raphaelroshan/jane-street-asic-lab/issues/4)
- M1: [execution engine](https://github.com/raphaelroshan/jane-street-asic-lab/issues/5),
  [deterministic-retirement proof](https://github.com/raphaelroshan/jane-street-asic-lab/issues/6)
- M2: [host SPI/CDC](https://github.com/raphaelroshan/jane-street-asic-lab/issues/7),
  [guardian and FIFO proofs](https://github.com/raphaelroshan/jane-street-asic-lab/issues/8)
- M3: [protocol firmware/models](https://github.com/raphaelroshan/jane-street-asic-lab/issues/9),
  [fault injection and trace](https://github.com/raphaelroshan/jane-street-asic-lab/issues/10)
- M4: [gate-level and physical closure](https://github.com/raphaelroshan/jane-street-asic-lab/issues/11)
- M5: [submission evidence](https://github.com/raphaelroshan/jane-street-asic-lab/issues/12)

## M0 — architecture freeze: September 17–30

- [x] Establish a tested, programmable teaching core
- [x] Complete the first CMOS5L GDS and precheck run
- [x] Select the single-engine verified peripheral-emulator direction
- [x] Draft UART, SPI, and I2C inner-loop cycle budgets
- [ ] Resolve the six open architecture decisions
- [x] Compare generic 32-word and 64-word program-store logic
- [ ] Harden 32-word and 64-word program stores in CMOS5L
- [ ] Freeze instruction semantics
- [x] Draft pin map and host register model
- [ ] Write tests for semantics before replacing teaching RTL

Exit criterion: no unresolved decision changes the top-level interface or
instruction state model.

## M1 — execution engine: October 1–25

- [ ] Implement 16-bit engine behind unit-level tests
- [ ] Implement assembler and disassembler
- [ ] Implement program loader and restart behavior
- [ ] Add deadline/timestamp semantics
- [ ] Prove deterministic retirement (P1)
- [ ] Harden engine plus program memory alone

Exit criterion: the engine executes a certified fixed UART waveform and stays
inside its four-tile engine budget plus program-store budget.

## M2 — data movement and guardian: October 26–November 15

- [ ] Add TX/RX FIFOs
- [ ] Add programmable pin mapping and output enable
- [ ] Add host SPI with documented CDC assumptions
- [ ] Add guardian permissions, open-drain mode, and watchdog
- [ ] Prove guardian and FIFO properties (P2–P4)
- [ ] Harden after each block lands

Exit criterion: host-loaded programs can exchange FIFO data and cannot bypass
pin safety.

## M3 — protocols and differentiator: November 16–December 1

- [ ] UART TX/RX firmware plus independent model
- [ ] SPI controller firmware plus modes 0–3 tests
- [ ] I2C peripheral firmware plus open-drain tests
- [ ] Selected NACK or delayed-ACK fault injection
- [ ] Shallow timestamped trace with explicit overflow
- [ ] First end-to-end program certificate

**Feature freeze: December 1.** USB, Ethernet, automatic recognition, additional
engines, and large memories remain out unless every M3 criterion is already
green.

## M4 — verification and physical closure: December 2–January 5

- [ ] Constrained-random regression and mutation checks
- [ ] Gate-level regression through public pins
- [ ] FPGA execution if suitable hardware is available
- [ ] 6x4 hardening with area, routing, and PVT timing report
- [ ] Reduce congestion and close all required checks
- [ ] Generate an evidence report from pinned tool versions

Exit criterion: one immutable commit produces all submission artifacts.

## M5 — submission: January 6–18

- [ ] Freeze RTL and firmware except for blocking correctness fixes
- [ ] Re-run complete evidence pipeline
- [ ] Polish datasheet, architecture diagrams, and limitations
- [ ] Record a short, reproducible demonstration
- [ ] Submit by January 18 with buffer for form/tooling problems

## Weekly operating rhythm

1. Begin with one measurable claim or failing test.
2. Write the smallest implementation change.
3. Run unit, RTL, lint, synthesis, and relevant formal checks.
4. Harden whenever sequential state or memory grows materially.
5. Record area/timing deltas in `docs/STATUS.md`.
6. End the week by deleting or deferring scope that lacks evidence.
