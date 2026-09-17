# Protocol Emulator ASIC Learning Lab

[![test](https://github.com/raphaelroshan/jane-street-asic-lab/actions/workflows/test.yaml/badge.svg)](https://github.com/raphaelroshan/jane-street-asic-lab/actions/workflows/test.yaml)
[![docs](https://github.com/raphaelroshan/jane-street-asic-lab/actions/workflows/docs.yaml/badge.svg)](https://github.com/raphaelroshan/jane-street-asic-lab/actions/workflows/docs.yaml)
[![gds](https://github.com/raphaelroshan/jane-street-asic-lab/actions/workflows/gds.yaml/badge.svg)](https://github.com/raphaelroshan/jane-street-asic-lab/actions/workflows/gds.yaml)

This is a learning-first starting point for Jane Street's
[protocol emulator ASIC competition](https://blog.janestreet.com/protocol-emulator-asic-competition/).
It is based on Tiny Tapeout's `cmos5l` Verilog template.

The checked-in RTL is **Lab 1, not the competition design**. It is a tiny
serially programmable timing engine intended to make clock-by-clock behavior
easy to understand. We will replace or evolve it only after writing down the
requirements and comparing architecture choices.

## Start here

```sh
make setup       # project-local simulator, synthesis tools, and Python env
make doctor      # show exactly which tools will run
make test        # assembler tests, RTL simulation, lint, and synthesis
```

`make setup` downloads the platform's OSS CAD Suite archive into the ignored
`.tools/` directory. Extracted tools currently use roughly 1.8 GB on macOS.
It does not modify Homebrew or require administrator access.

### Windows

Use Windows 11 with WSL2 and an Ubuntu distribution. From PowerShell in the
repository, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1
```

The launcher installs the small Ubuntu prerequisites, downloads the Linux OSS
CAD Suite inside the project, creates the Python environment, and runs all
tests. It may prompt for your WSL password while installing Ubuntu packages.
Afterward, develop from a WSL terminal or VS Code's WSL extension:

```sh
make doctor
make test
```

Native PowerShell simulation is intentionally not the primary path: Tiny
Tapeout's eventual LibreLane physical-design flow is Linux-oriented, so using
WSL from day one avoids maintaining two subtly different environments.

Then read these in order:

1. [`docs/DESIGN.md`](docs/DESIGN.md) — the four-instruction Lab 1 machine.
2. [`src/timing_core.v`](src/timing_core.v) — about one page of real RTL.
3. [`test/test.py`](test/test.py) — the executable clock-edge specification.
4. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — the draft competition MVP.
5. [`docs/CYCLE_BUDGETS.md`](docs/CYCLE_BUDGETS.md) — protocol timing pressure on the ISA.
6. [`docs/HOST_INTERFACE.md`](docs/HOST_INTERFACE.md) — candidate pin, SPI, and register contract.
7. [`docs/VERIFICATION_PLAN.md`](docs/VERIFICATION_PLAN.md) — proof obligations and evidence layers.
8. [`docs/ROADMAP.md`](docs/ROADMAP.md) — milestones through January 18, 2027.
9. [`docs/STATUS.md`](docs/STATUS.md) — measured physical results and known gaps.
10. [`docs/RESEARCH.md`](docs/RESEARCH.md) — public evidence behind the direction.
11. [`docs/DESIGN_WORKBOOK.md`](docs/DESIGN_WORKBOOK.md) — questions and experiments for you to resolve.
12. [`docs/RESOURCE_GUIDE.md`](docs/RESOURCE_GUIDE.md) — decision-oriented primary resources.
13. [`docs/LEARNING_PATH.md`](docs/LEARNING_PATH.md) — staged exercises.

Generate the demo program bytes:

```sh
.venv/bin/python tools/lab_asm.py
```

## What is automated—and what is not

Automated: repeatable tool installation, encoding checks, RTL simulation,
linting, synthesis, and eventually the Tiny Tapeout GDS workflow.

Kept human-visible: protocol timing calculations, ISA decisions, CDC choices,
area/timing interpretation, test-oracle design, and every architecture change.
The goal is to automate repetition and evidence, not judgment.

## Repository status

- Lab allocation remains `1x1`; do not change it to the competition allocation
  until Jane Street and Tiny Tapeout resolve the current template-size mismatch.
- Bidirectional pins are reserved for the later host-interface/I2C lab.
- The CMOS5L GDS build, Tiny Tapeout precheck, gate-level simulation, and GDS
  viewer pass for the teaching core; see [`docs/STATUS.md`](docs/STATUS.md).
- The project direction is a single-engine verified peripheral emulator with
  an independent safety guardian. The submission architecture remains a draft;
  the checked-in RTL is still the teaching core.
