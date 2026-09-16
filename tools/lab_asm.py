#!/usr/bin/env python3
"""Transparent encoder for the disposable Lab 1 ISA.

There is intentionally no parser yet: encoding functions keep the relationship
between each instruction field and the RTL obvious.
"""

OP_SET = 0b00
OP_WAIT = 0b01
OP_JUMP = 0b10
OP_WAIT_PIN = 0b11


def _bounded(name: str, value: int, maximum: int) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise TypeError(f"{name} must be an integer")
    if not 0 <= value <= maximum:
        raise ValueError(f"{name} must be between 0 and {maximum}")
    return value


def set_pin(pin: int, value: int) -> int:
    return (OP_SET << 6) | (_bounded("pin", pin, 7) << 3) | (
        _bounded("value", value, 1) << 2
    )


def wait(cycles: int) -> int:
    """Insert `cycles` idle clocks after the WAIT instruction retires."""
    return (OP_WAIT << 6) | _bounded("cycles", cycles, 63)


def jump(address: int) -> int:
    return (OP_JUMP << 6) | _bounded("address", address, 15)


def wait_pin(pin: int, value: int) -> int:
    return (OP_WAIT_PIN << 6) | (_bounded("pin", pin, 7) << 3) | (
        _bounded("value", value, 1) << 2
    )


if __name__ == "__main__":
    demo = [set_pin(0, 1), wait(2), set_pin(0, 0), wait(1), jump(0)]
    print(" ".join(f"{word:02x}" for word in demo))
