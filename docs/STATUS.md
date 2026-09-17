# Project status and evidence

Last updated: 2026-09-17.

## Current state

The repository contains a disposable 8-bit teaching ISA, not the submission
engine.  It demonstrates serial program loading and clock-exact `SET`, `WAIT`,
`JUMP`, and `WAIT_PIN` behavior.

Passing locally and in the primary GitHub test workflow:

- assembler unit tests
- two public-pin cocotb timing tests
- Verilator lint
- generic Yosys synthesis
- Tiny Tapeout documentation check

## CMOS5L baseline

Measured metrics came from
[GitHub Actions 35054434078](https://github.com/raphaelroshan/jane-street-asic-lab/actions/runs/35054434078),
commit `fed8ad9`.  A later clean baseline run,
[GitHub Actions 35185459218](https://github.com/raphaelroshan/jane-street-asic-lab/actions/runs/35185459218),
commit `5a12cdf`, passes GDS, precheck, gate-level simulation, and viewer jobs.

The GDS build and Tiny Tapeout precheck completed successfully for a 1x1 tile.

| Metric | Baseline result |
|---|---:|
| Synthesized cells | 918 |
| Synthesized cell area | 14,986.7 um2 |
| Sequential cells | 164 |
| Placed standard cells | 1,323 |
| Placed standard-cell utilization | 72.7% |
| Final route DRC errors | 0 |
| LVS errors | 0 |
| Worst setup slack at 20 ns | +11.81 ns |
| Worst hold slack | +0.139 ns |
| Timing-repair buffers | 352 |
| Clock buffers | 49 |

This is a valuable warning: even the 128-bit flip-flop program store dominates
sequential area and the physical flow adds substantial clock/timing repair.
Future memories require full hardening evidence, not only generic cell counts.

## Infrastructure notes

### Gate-level simulation

The first CMOS5L gate-level job failed during model elaboration because the
template omitted `sg13cmos5l_udp.v`, leaving the `ihp_dff_r` primitive
unresolved.  Including the PDK UDP model in `test/Makefile` fixed the issue;
run 35185459218 confirms the gate-level suite passes.

### GDS viewer

GitHub Pages is configured for workflow deployment.  The GDS viewer job now
passes and publishes the baseline layout.

### Competition allocation

Jane Street currently says to use 6x4 tiles while the public template metadata
still documents a different set of accepted tile strings.  The learning core
remains 1x1 until the competition/template update is published.

### Local full hardening

The laptop's existing Colima VM currently fails to start with a macOS
virtualization/FUSE error.  RTL tools run from the project-local OSS CAD Suite;
GitHub Actions is the current CMOS5L flow of record.
