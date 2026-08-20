# Unified agent usage implementation package

Roadmap: [unified-agent-usage](../../roadmap/unified-agent-usage/README.md)  
Branch: `chore/roadmap-unified-agent-usage`  
PR: #898  
Planned at: `92d21efb`

All rows execute sequentially in this branch and this PR. Do not create another
branch or PR. Re-read current state before every row because earlier rows modify the
same integration seams.

| Plan | Outcome | Depends on | Status |
|---|---|---|---|
| [001](001-freeze-contract-and-baseline.md) | Executable contract/baseline gates | — | TODO |
| [002](002-build-canonical-projection.md) | Canonical identity and V1 projection | 001 | TODO |
| [003](003-build-durable-broker.md) | Process-independent broker authority | 002 | TODO |
| [004](004-complete-provider-adapters.md) | Eight-provider quota parity | 002, 003 | TODO |
| [005](005-ship-cli-and-console.md) | Simple CLI and native Console Usage | 003, 004 | TODO |
| [006](006-ship-capsule-usage.md) | Resolved-agent Capsule Usage | 003, 004 | TODO |
| [007](007-ship-desktop-usage.md) | FFI, popover, and native Usage window | 003, 004 | TODO |
| [008](008-prove-parity-and-release.md) | Cross-surface proof and signed distribution | 005, 006, 007 | TODO |

Frozen package fingerprint: `6c396a1a6f6816a619acfc63f4a3932bccba77c0`.

## Execution rules

- One row at a time; commit with DCO and required co-author trailer; push immediately.
- Keep PR #898 updated. Never create a branch or PR from a plan.
- A zero-test Cargo filter is failure. Fix the named test target before advancing.
- Preserve unrelated work. Stop on source drift that invalidates cited seams.
- Update roadmap/docs in the same PR as behavior.
