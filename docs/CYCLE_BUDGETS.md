# Draft protocol cycle budgets

Status: **DRAFT input to ISA issue #3.** These calculations specify required
semantics; they do not assume a final bit encoding.

## Common assumptions

- Nominal system clock: 50 MHz, 20 ns per clock
- Normal instruction retirement: one system clock
- Inputs are consumed only after synchronization as `event_seen`
- Pin outputs are registered
- Timing claims below are digital cycle budgets, not pad/electrical guarantees
- Certified response paths use bounded loops and waits with timeout

## Proposed capability targets

| Protocol | Required MVP | Goal if inexpensive |
|---|---|---|
| UART | TX/RX, 8N1, 9,600–1,000,000 baud | parity and configurable stop bits |
| SPI | controller, modes 0–3, 5 MHz SCLK | 10 MHz SCLK and peripheral role |
| I2C | peripheral, 100/400 kHz, ACK/NACK, repeated start | controller role and clock stretching |

The targets intentionally leave margin below Tiny Tapeout I/O ratings and keep
the protocol suite testable with ordinary development boards.

## UART

At 50 MHz:

| Baud | Ideal clocks/bit | Integer clocks | Actual baud | Error |
|---:|---:|---:|---:|---:|
| 9,600 | 5208.333 | 5208 | 9600.614 | +0.0064% |
| 115,200 | 434.028 | 434 | 115207.373 | +0.0064% |
| 1,000,000 | 50.000 | 50 | 1000000.000 | 0% |

Integer periods are already accurate enough for these representative rates;
fractional clock-divider hardware is therefore not an MVP requirement.

### TX inner-loop requirement

A plausible bit iteration is:

```text
wait until bit deadline
shift OSR bit to TX pin
advance deadline by clocks_per_bit
decrement/branch
```

At 1 Mbaud this consumes at most four active clocks out of a 50-clock bit
period.  Even a less compact six-instruction loop retains 44 clocks of slack.
This requires a shift-to-pin operation, deadline wait/update, and bounded loop.

### RX inner-loop requirement

After a synchronized falling start edge:

1. schedule the first data sample approximately 1.5 bit periods later;
2. sample one bit into ISR;
3. advance the absolute deadline by one bit period;
4. repeat eight times;
5. validate the stop bit and push the byte.

Using absolute deadlines prevents branch or FIFO bookkeeping from accumulating
phase error.  Synchronizer phase uncertainty is treated separately from this
post-`event_seen` schedule.

## SPI

The SPI target is the main instruction-density constraint.

| SCLK | System clocks/bit | Clocks/half-period |
|---:|---:|---:|
| 5 MHz | 10 | 5 |
| 10 MHz | 5 | 2.5 |
| 12.5 MHz | 4 | 2 |

### Conservative controller loop

Without side-set or zero-overhead wrapping, a bit may require:

```text
1  drive next MOSI value
1  drive leading SCLK edge
1  sample MISO
1  drive trailing SCLK edge
1  shift/update loop state
1  bounded branch
```

Six clocks/bit cannot reach 10 MHz at a 50 MHz system clock, but fits the 5 MHz
MVP target with four clocks of margin for phase placement.

### ISA pressure revealed by SPI

Reaching the 10 MHz goal requires at least one of:

- side-set: change SCLK while executing shift/sample instructions;
- an atomic `SHIFT_OUT + pin value` operation;
- automatic loop wrapping without a branch instruction;
- a small per-instruction delay/phase field.

The ISA decision should compare the area cost of these features against their
benefit.  The MVP must not add broad complexity solely to advertise 10 MHz.

Modes 0–3 require configurable idle level and a choice of leading or trailing
sample edge; they do not require separate protocol RTL.

## I2C

Relevant minimum timing translated to a 50 MHz clock:

| Mode | Period target | Minimum low | Minimum high | Data setup |
|---|---:|---:|---:|---:|
| Standard, 100 kHz | 500 clocks | 235 clocks | 200 clocks | 13 clocks |
| Fast, 400 kHz | 125 clocks | 65 clocks | 30 clocks | 5 clocks |

These values are derived from 4.7 us/4.0 us/250 ns for Standard-mode and
1.3 us/0.6 us/100 ns for Fast-mode in
[NXP UM10204, I2C-bus specification and user manual, Rev. 7.0 — 1 October 2021](https://www.nxp.com/docs/en/user-guide/UM10204.pdf).
The verification environment must retain this revision rather than silently
following a moving web reference.

### Peripheral ACK response

After observing the eighth SCL sampling edge, the engine has the following SCL
low phase—at least 65 clocks in Fast-mode—to decide ACK/NACK and release or pull
SDA low before the next rising edge.  A target of eight engine clocks from
`event_seen` to guardian-approved SDA action leaves substantial margin.

### Required semantics

- runtime output-enable control; open-drain high means release, never drive one
- wait for synchronized SCL/SDA level or edge with timeout
- shift input data into ISR and output data from OSR
- start/repeated-start/stop detection in firmware
- optional bounded clock-stretch wait

A 16-bit timeout covers 65,535 system clocks, approximately 1.31 ms at 50 MHz.
I2C permits longer device-dependent stretching, so the limit must be documented
or extended in firmware rather than presented as universal compliance.

## Resulting ISA requirements

The cycle budgets justify the following semantic minimum:

1. output or shift a bit while controlling a selected pin group;
2. sample or shift a selected input bit;
3. change bidirectional output enable through the guardian;
4. set and increment an absolute deadline;
5. wait for deadline;
6. wait for pin level/edge with timeout;
7. execute a statically bounded loop;
8. push/pull a word without hidden variable latency;
9. optionally side-set one or two pins if area measurements justify the 10 MHz
   SPI goal.

## Questions for ISA freeze

- Is 5 MHz SPI sufficient for the competition story, making side-set optional?
- Can one instruction atomically shift a data bit and drive a clock side-set
  without making static analysis obscure?
- Should bounded loops use a dedicated decrement-and-branch instruction or a
  zero-overhead wrap register?
- Is `WAIT_EDGE` hardware worthwhile, or can synchronized level waits plus
  firmware state provide the same behavior safely?
- Which operations may stall, and how is every stall exposed to the analyzer?
