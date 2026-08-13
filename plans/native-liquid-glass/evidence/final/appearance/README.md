# Liquid Glass preference evidence

macOS exposes no public API for reading or changing the Clear/Tinted Liquid Glass preference. These records therefore pair explicit operator attestations with real System Settings, Usage-window, and popover captures. The capture process never changes the preference.

## A08 — Clear

- Operator attestation: `Clear ready`
- Setting receipt: [`setting-clear.png`](setting-clear.png), showing Clear selected; SHA-256 `f44aebde2586bf05a70982c1ad5c102d00f9086eb04958bfc2a6bc482d749bf0`.
- Usage: [`usage-clear-F02.png`](usage-clear-F02.png), captured `2026-08-13T02:01:53Z`; real layer-0 key window.
- Popover: [`popover-clear-F02.png`](popover-clear-F02.png), captured `2026-08-13T02:01:59Z`; real layer-25 transient surface.
- Product/test source: `7c8fca3fcbfa02f50e80ec1364475bd396173b98`.
- Application SHA-256: `4931f501c9e54620da9f89908809b32f6efe3bf84e1933a61fa5f4fc3761ed0b`.
- Result: both surfaces remain legible and structurally unchanged at the clearer extreme. System glass stays in functional chrome; content, sidebar identity, hierarchy, and fixed leading sidebar control remain clear.

## A09 — Tinted

- Operator attestation: `Tinted ready`
- Setting receipt: [`setting-tinted.png`](setting-tinted.png), showing Tinted selected; SHA-256 `7bc45fdc162e70b0df19640cbe559400da6ab61189f014df068b49f543a858a4`.
- Usage: [`usage-tinted-F02.png`](usage-tinted-F02.png), captured `2026-08-13T02:06:51Z`; real layer-0 key window.
- Popover: [`popover-tinted-F02.png`](popover-tinted-F02.png), captured `2026-08-13T02:06:56Z`; real layer-25 transient surface.
- Product/test source: `7c8fca3fcbfa02f50e80ec1364475bd396173b98`.
- Application SHA-256: `4931f501c9e54620da9f89908809b32f6efe3bf84e1933a61fa5f4fc3761ed0b`.
- Result: both surfaces remain legible and structurally unchanged at the more opaque extreme. Tinted system chrome gains stronger separation without tinting content or weakening jackin❯ hierarchy.

## Restoration

- Original preference: Clear.
- Operator attestation: `Original Clear restored`.
- Receipt: [`setting-restored.png`](setting-restored.png), showing Clear selected; SHA-256 `ade836c2ff1e89dd2d326254156330dd6a453ef8d3aacfa6cf3fb6819fadeeeb`.
- Result: the original preference is restored. System Settings was closed again after the receipt, matching its pre-capture application state.
