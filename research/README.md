# Research

| Topic | One-line summary | Informs | Updated |
|-------|------------------|---------|---------|
| [termrock-head-adoption](termrock-head-adoption/README.md) | Bump to TermRock head `e1d61f4d` = measured 384-error mechanical migration + 40 applicable migration docs; brand chrome recolors on bump alone; PNG baseline pipeline adoptable as git dep | termrock-migration | 2026-08-19 |
| [jackin-verification-tooling](jackin-verification-tooling/01-gates-and-commands.md) | Proven gates: full merge-readiness = `cargo xtask ci` (`--fast` skips powerset; `--only <partition>` repeatable); `mise run ci` is a 3-partition subset, NOT the full gate; snapshot re-bless = `INSTA_UPDATE=new cargo nextest run …` (cargo-insta not installed) | termrock-migration | 2026-08-19 |
