# Plan 002: Build canonical identity and projection V1

## Status
TODO

## Why this matters
Deduplication, order, selection, and parity require one surface-neutral Rust truth.

## Preconditions — run before anything else
Plan 001 DONE; read canonical-projection spec and research 06; verify cited symbols still exist.

## Spec contract
Canonical projection: one V1 projection, evidence identity, deterministic membership/order, Rust semantics, selection removal.

## Must NOT
N1, N4, N8-N10, N14.

## Inputs to provide
V1 fixtures, current protocol records, discovery/catalog/coordinator state, provider labels.

## Starting state
Account generations and desktop-shaped aggregate exist; authenticated labels/source IDs can influence identity.

## Commands you will need
`rtk cargo test -p jackin-usage canonical_projection -- --test-threads=1`; protocol tests; fmt/clippy.

## Suggested executor toolkit
Serde, existing coordinator state store, property tests for merge/order/collision.

## Scope
Protocol V1 records; canonical evidence/alias/merge; discovery membership; Rust labels/order/formatting; projection publication. No consumer UI.

## Git workflow
Current branch/PR only. Commit/push cohesive checkpoints; never rewrite published history without approval.

## Steps
### Step 1: Add secret-free V1 wire records
Implement schema version, projection/provider/account/window/freshness/issue/unresolved records and compatibility tests.
### Step 2: Replace ordinal/label identity
Implement typed evidence ladder, domain-separated IDs, collision failure, provisional unresolved capability, atomic alias transition.
### Step 3: Separate membership, merge, and ordering
Use current discovery only for membership; deterministic precedence; fixed provider orders; locale-stable account ranks; provider window ranks.
### Step 4: Publish immutable generations
Build atomic projection from committed account state and retain last-good on partial failure.
### Step 5: Add destination normalization helper
Account-only multi-provider destinations and explicit removal result/notice; no presentation selection in JSON.

## Test plan
Duplicate discovery, collision, alias replay/crash, empty/unresolved, stable order under severity changes, unknown schema, partial failure, golden JSON.

## Done criteria
Canonical target passes; all fixtures have one account per evidence identity; no source ordinal/secret/agent name in IDs or labels.

## STOP conditions
Provider lacks non-secret identity and implementation guesses one; cross-platform collation differs; V1 exceeds transport bound without measured redesign.

## Maintenance notes
Breaking V1 meaning needs major schema; additive fields require compatibility fixture.

