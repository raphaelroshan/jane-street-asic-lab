# Copyright (c) 2026 Raphael Roshan
# SPDX-License-Identifier: Apache-2.0

"""Executable timing specification for Lab 1.

Read this beside src/timing_core.v. The assertions are intentionally about
individual clock edges so instruction timing cannot hide behind a high-level
protocol model.
"""

from pathlib import Path
import sys

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, ReadOnly

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from lab_asm import jump, set_pin, wait, wait_pin  # noqa: E402


async def clock_edge(dut):
    await RisingEdge(dut.clk)
    await ReadOnly()
    return int(dut.uo_out.value)


async def reset_and_load(dut, program):
    """Reset, then shift each instruction MSB-first into instruction memory."""
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.ui_in.value = 0x80  # load_mode=1, serial_data=0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    for instruction in program:
        for bit in range(7, -1, -1):
            await FallingEdge(dut.clk)
            dut.ui_in.value = 0x80 | ((instruction >> bit) & 1)
            await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.ui_in.value = 0  # load_mode=0; instruction zero executes next edge


@cocotb.test()
async def test_precise_wait_timing(dut):
    """SET/WAIT/JUMP produces the exact edge sequence documented in DESIGN.md."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    program = [
        set_pin(0, 1),
        wait(2),
        set_pin(0, 0),
        wait(1),
        jump(0),
    ]
    await reset_and_load(dut, program)

    observed = [(await clock_edge(dut)) & 1 for _ in range(9)]
    assert observed == [1, 1, 1, 1, 0, 0, 0, 0, 1]


@cocotb.test()
async def test_wait_pin_stalls_until_match(dut):
    """WAIT_PIN holds the PC, then retires one edge before the following SET."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    program = [
        set_pin(1, 0),
        wait_pin(2, 1),
        set_pin(1, 1),
        jump(3),
    ]
    await reset_and_load(dut, program)

    assert ((await clock_edge(dut)) >> 1) & 1 == 0  # SET low
    assert ((await clock_edge(dut)) >> 1) & 1 == 0  # begin waiting
    for _ in range(3):
        assert ((await clock_edge(dut)) >> 1) & 1 == 0

    await FallingEdge(dut.clk)
    dut.ui_in.value = 1 << 2
    assert ((await clock_edge(dut)) >> 1) & 1 == 0  # WAIT_PIN retires
    assert ((await clock_edge(dut)) >> 1) & 1 == 1  # following SET executes
