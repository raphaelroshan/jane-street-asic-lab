# Program-store sizing experiment

This experiment isolates a 16-bit-wide, synchronous-write,
asynchronous-read flip-flop program store.  It matches the convenient fetch
semantics of the teaching core but is not submission RTL.

Run:

```sh
make measure-memory
```

Generic Yosys results with OSS CAD Suite 2026-09-15:

| Depth | Total generic cells | DFFEs | Muxes |
|---:|---:|---:|---:|
| 32 x 16 | 1,418 | 512 | 320 |
| 64 x 16 | 2,841 | 1,024 | 655 |

Doubling depth approximately doubles both storage flops and read-selection
logic.  These counts do not include a program counter, loader, engine, clock
tree, hold repair, or routing.  They are useful for rejecting the idea that a
64-word store is nearly free; they are not sufficient for the final choice.

Decision evidence still required:

1. CMOS5L mapping and hardening for both depths;
2. timing of the asynchronous read path at 50 MHz;
3. routing/clock-repair overhead;
4. actual assembled UART, SPI, and I2C program lengths;
5. comparison with a synchronous SRAM/macro option if flip-flop storage
   consumes too much of the 24-tile budget.
