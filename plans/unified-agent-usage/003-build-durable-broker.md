# Plan 003: Build the durable single-authority broker

## Status
TODO

## Why this matters
Single-flight inside an activating process does not survive owner exit or prevent consumer bypasses.

## Preconditions — run before anything else
Plans 001–002 DONE; read broker-refresh spec and research 06; isolate test state under workspace-owned paths.

## Spec contract
Broker: durable authority, joined work, adaptive cadence, recoverable persistence.

## Must NOT
N3, N4. No silent launchd or host configuration writes.

## Inputs to provide
V1 protocol, current coordinator/broker/store, fake clock/executor, process test harness.

## Starting state
Broker thread belongs to first caller, PID-only election exists, consumers retain bypass/cache controls.

## Commands you will need
`rtk cargo test -p jackin-usage broker_service_lifecycle -- --test-threads=1`; coordinator/broker suites; fmt/clippy.

## Suggested executor toolkit
Independent broker executable, mode-0600 Unix socket, atomic lease/state, process-level integration tests.

## Scope
Demand activation spike and implementation; handshake; service lifecycle; catalog revision; deadlines; joins; cancellation; crash recovery; protocol operations.

## Git workflow
Current branch/PR only; push each signed commit. Do not install host services.

## Steps
### Step 1: Prove activation direction
Test concurrent cold start, activator exit, PID reuse, incompatible healthy broker, idle restart, exact-generation joins. If invariant fails, stop and document resident-service reslice.
### Step 2: Split client and executor lifetime
Clients activate/connect only; independent service loads state, binds authenticated endpoint, publishes readiness.
### Step 3: Implement projection operations
CurrentProjection, RequestRefresh, and JoinPublication with catalog/generation IDs and relay allowlists.
### Step 4: Centralize policy
Implement fake-clock 2/5/15/30 cadence, provider deadlines/backoff, force constraints, cancellation isolation, no follow-up queue.
### Step 5: Harden persistence/recovery
Atomic publication, alias/catalog transaction, corrupt-state quarantine, owner-lost recovery, immutable last-good.

## Test plan
Adversarial multi-process suite plus legacy coordinator/broker tests, transport permissions, crash fault injection, zero direct executor construction by clients.

## Done criteria
Owner exit survives; four concurrent clients see one generation; retry/cadence restored after restart; static audit has one provider authority.

## STOP conditions
In-process fallback needed; endpoint permits another user; crash can publish mixed state; test writes outside approved workspace paths.

## Maintenance notes
Broker protocol/persistence versions and policy constants live in one module with fake-clock tests.

