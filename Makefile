LAB_ROOT := $(CURDIR)
OSS_CAD_BIN := $(LAB_ROOT)/.tools/oss-cad-suite/bin
PYTHON := $(LAB_ROOT)/.venv/bin/python
VERILATOR := $(if $(wildcard $(OSS_CAD_BIN)/verilator),$(OSS_CAD_BIN)/verilator,verilator)
YOSYS := $(if $(wildcard $(OSS_CAD_BIN)/yosys),$(OSS_CAD_BIN)/yosys,yosys)

.PHONY: setup doctor test unit-test rtl-test lint synth measure-memory clean

setup:
	./scripts/setup.sh

doctor:
	@./scripts/doctor.sh

test: unit-test rtl-test lint synth

unit-test:
	$(if $(wildcard $(PYTHON)),$(PYTHON),python3) -m pytest -q tools/test_lab_asm.py

rtl-test:
	PATH="$(OSS_CAD_BIN):$$PATH" $(MAKE) -C test clean
	PATH="$(OSS_CAD_BIN):$$PATH" $(MAKE) -C test

lint:
	$(VERILATOR) --lint-only -Wall -Wno-fatal -Wno-DECLFILENAME src/timing_core.v src/project.v

synth:
	$(YOSYS) -q -p 'read_verilog src/timing_core.v src/project.v; synth -top tt_um_raphaelroshan_protocol_lab; stat'

measure-memory:
	./scripts/measure-program-store.sh

clean:
	PATH="$(OSS_CAD_BIN):$$PATH" $(MAKE) -C test clean
