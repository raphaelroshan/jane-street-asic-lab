# ADR 0002: certification boundary and physical timing claims

Status: Accepted for planning, 2026-09-17.

## Context

The product direction calls for bounded latency and proof-carrying or certified
microprograms.  Asynchronous pins, metastability, pad delay, and PVT behavior
cannot be proven by a digital RTL model.

## Decision

Formal response-latency claims begin at the synchronized internal
`event_seen`.  A host-side analyzer certifies bounded program paths.  Formal
properties prove that the engine and guardian implement their cycle model.
Post-route STA supports the system-clock claim.  FPGA and silicon measurements
characterize latency from a physical pin edge.

The MVP does not include an on-chip theorem prover or cryptographic certificate
checker.  A certificate is a reproducible host artifact tied to exact program
bytes.  Runtime enforcement comes from simple hardware permissions, timeout,
watchdog, and fail-safe output release.

## Consequences

- Marketing language must say "within N clocks of `event_seen`," not "within N
  clocks of any physical edge," unless measurement assumptions are also given.
- Synchronizer depth and input filter configuration are part of every protocol
  manifest.
- Formal assumptions must be visible in generated evidence.
- Flexibility is preserved: raw programs may run, but only analyzer-accepted
  programs receive timing certificates.
