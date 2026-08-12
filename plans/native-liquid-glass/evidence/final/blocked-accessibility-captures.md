# Blocked native setting evidence

Status: **implementation complete; host-only captures unavailable without restarting the macOS GUI session**

## Accessibility setting captures

The capture harness successfully applied Reduce Transparency through `state.sh with`, launched the exact validated app, resolved the real Usage window, and then received `could not create image from window` from `screencapture` on all three attempts. The wrapper restored every snapshotted setting before returning failure. A baseline window capture then failed the same way, so further Increase Contrast, Reduce Motion, and Differentiate Without Color image attempts could not add trustworthy evidence.

Full-screen `screencapture` returned an all-black image. ScreenCaptureKit returned `SCStreamErrorDomain Code=-3811` (`Failed to start stream due to audio/video capture failure`). Region capture returned `could not create image from rect`. These failures establish a macOS capture-service state, not an application rendering failure. The earlier 36 native captures remain valid, hashed, and tied to the exact app executable.

XCTest remained the permission-independent fallback, but the host test runner then failed before launching any test with `LocalAuthentication Code=-4` (`System authentication is running`). Restarting only the per-user LocalAuthentication UI agent and daemon did not clear the system-owned authentication state. Restarting the full GUI session or host would be an external destructive interruption and was not performed.

Code does not branch on these settings and contains no custom material, glass, blur, opacity, motion, glow, custom progress track, or color-only status. Standard `NSPopover`, `NavigationSplitView`, `Table`, `List`, `Form`, `Section`, `Picker`, `Button`, and `ProgressView` components therefore retain system ownership of accessibility adaptation. Default-state UI audits passed on Overview, provider detail, and the real popover before the host service entered this state.

## Clear and tinted Liquid Glass preferences

macOS provides no public API that identifies the operator's clear/tinted Liquid Glass preference. The application intentionally does not read or infer it. A08 and A09 remain operator-owned manual observations after choosing each preference in System Settings; layout and semantics are unchanged because all material is system-owned.

## Restoration result

`settings-before.txt`, `settings-after-recovery.txt`, and `settings-after-trap-test.txt` have the same SHA-256: `d1b88cdf87446cb235e617faf110014e3164e247d8ab96935df1e23900d92d87`. The later focus snapshots add `AppleKeyboardUIMode`; all five, including `settings-current.txt`, have the same SHA-256: `821f1c28b1034fbfb139830116d71472b21a168334a353b2bc7b87ff7ca0be07`. No tested macOS preference remains modified.
