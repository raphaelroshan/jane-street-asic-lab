# Draft host interface and pin contract

Status: **DRAFT for issue #4.** The framing is intentionally conservative so
the first implementation can be oversampled in one clock domain and verified
without an asynchronous FIFO.

## Physical pin allocation

| Pins | Direction | Contract |
|---|---|---|
| `ui[7:0]` | input | Programmable sample-only protocol pins 0–7 |
| `uo[7:0]` | output | Programmable drive-only protocol pins 8–15 |
| `uio[3:0]` | bidirectional | Guardian-mediated protocol pins 16–19 |
| `uio[4]` | input | Host SPI `CS_n` |
| `uio[5]` | input | Host SPI `SCK` |
| `uio[6]` | input | Host SPI `MOSI` |
| `uio[7]` | output | Host SPI `MISO` |

Host pins are never visible in the program's logical GPIO namespace.  The
guardian may release `uio[3:0]`; it cannot alter host-pin directions.

## Host SPI electrical/timing contract

- SPI mode 0, MSB first
- System clock nominally 50 MHz
- Host `SCK <= clk/8`, initially 6.25 MHz at 50 MHz
- `CS_n` must be asserted at least four system clocks before the first rising
  SCK edge
- MOSI remains stable for its normal SPI setup/hold interval around each edge
- Raising `CS_n` aborts and resets an incomplete frame without side effects

`CS_n`, `SCK`, and `MOSI` pass through two-flop synchronizers.  The receiver
detects synchronized SCK edges in the system domain.  MISO changes after a
detected falling edge so it is stable before the next physical rising edge at
the documented clock ratio.  STA and hardware measurement must validate the
external MISO margin; RTL simulation alone is insufficient.

## Fixed 24-bit frame

Every assertion of `CS_n` transfers exactly one command byte and one 16-bit
word:

```text
bit 23       write=1, read=0
bits 22:21   address space
bits 20:16   word address 0..31
bits 15:0    write data or read-response clocks
```

Read data is latched when the command byte completes and shifted out during
the final 16 clocks.  Writes and read side effects commit only when all 24 bits
have arrived.  There is no auto-increment in the MVP.  Loading 32 instructions
therefore requires 32 small, independently abortable frames.

Reads from reserved addresses return zero.  Complete writes to reserved or
read-only addresses have no functional side effect and set an invalid-command
violation bit.  This keeps every command byte deterministic and observable.

## Address spaces

| Space | Purpose |
|---:|---|
| `00` | Global control, status, and guardian configuration |
| `01` | Engine configuration and debug state |
| `10` | Program memory, one 16-bit instruction per address |
| `11` | TX/RX FIFO and trace streaming ports |

## Draft global registers (`space=00`)

| Address | Name | Access | Purpose |
|---:|---|---|---|
| `0x00` | ID | R | Fixed implementation identifier |
| `0x01` | VERSION | R | Interface/RTL version |
| `0x02` | CONTROL | RW | Enable, restart, trace arm, sticky-flag clear |
| `0x03` | STATUS | R | Running, waiting, halted, FIFO and trace state |
| `0x04` | VIOLATIONS | R/W1C | Watchdog, deadline, permission, FIFO, trace flags |
| `0x05` | DRIVE_MASK_LO | RW | Guardian drive permissions for pins 0–15 |
| `0x06` | DRIVE_MASK_HI | RW | Guardian drive permissions for pins 16–19 |
| `0x07` | OPEN_DRAIN_LO | RW | Open-drain policy for pins 0–15 |
| `0x08` | OPEN_DRAIN_HI | RW | Open-drain policy for pins 16–19 |
| `0x09` | WATCHDOG_LIMIT | RW | Maximum clocks between guardian checkpoints |
| `0x0a` | PROGRAM_LENGTH | RW | Highest valid program address plus one |
| `0x0b` | START_PC | RW | PC loaded by restart |
| `0x0c` | TRACE_CONFIG | RW | Event mask and trace enable policy |

Writes to configuration are accepted only while the engine is disabled.  A
rejected write sets a configuration-violation flag rather than silently
changing live behavior.

## Draft engine/debug registers (`space=01`)

| Address | Name | Access |
|---:|---|---|
| `0x00` | PC and execution state | R |
| `0x01` | X | R; writable while disabled |
| `0x02` | Y | R; writable while disabled |
| `0x03` | ISR | R |
| `0x04` | OSR | R; writable while disabled |
| `0x05` | TIME | R |
| `0x06` | DEADLINE | R; writable while disabled |
| `0x07` | LAST_EVENT | R |

Single-step and execute-immediate commands are useful for debugging but remain
stretch features until their area and state interactions are understood.

## Program memory (`space=10`)

Addresses `0x00`–`0x1f` hold the MVP's 32 instructions.  Writes are rejected
while the engine is enabled.  Restart validates `START_PC < PROGRAM_LENGTH`;
invalid metadata leaves the engine disabled and sets a violation flag.

The single-bank MVP is safely updated by disable → write → configure length/PC
→ restart.  Dual-bank atomic activation remains a stretch goal because it
doubles the largest sequential block.

## Stream ports (`space=11`)

| Address | Name | Access | Side effect at complete frame |
|---:|---|---|---|
| `0x00` | TX_PUSH | W | Push one word or set overflow/full violation |
| `0x01` | RX_POP | R | Pop the word latched for this completed read |
| `0x02` | FIFO_LEVELS | R | TX/RX occupancy and full/empty bits |
| `0x03` | TRACE_POP | R | Pop one packed trace token |
| `0x04` | TRACE_LEVEL | R | Trace occupancy, empty, full, overflow |

Empty pops return zero and set an explicit underflow flag.  Full pushes do not
overwrite old data.  These behaviors are included in formal property P4.

## Reset and recovery

- `rst_n=0` releases all protocol bidirectional pins and disables execution.
- Host SPI remains available after reset release.
- Program memory contents are unspecified after reset and must not execute
  until valid length/start metadata is committed and restart is requested.
- Watchdog or fatal guardian violation releases protected pins and halts the
  engine; host status and trace remain readable.
- TT `ena` is infrastructure selection, not a host run/load control.

## Verification requirements before freeze

- aborted frames have no write, push, or pop side effects
- every 256 command byte values has defined behavior
- SPI timing is randomized up to the documented SCK limit
- configuration writes during execution are rejected visibly
- incomplete program loading cannot start execution accidentally
- reset or watchdog release never depends on host progress
- the same host driver works against RTL, gates, FPGA, and silicon
