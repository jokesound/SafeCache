# SafeCache 0.2 Security Audit

## Destructive surface

Source scan result: only `SafeCache/CacheCleaner.m` contains destructive filesystem primitives. There are exactly two `unlinkat()` call sites:

- regular file removal relative to an opened directory FD;
- empty directory removal relative to an opened parent directory FD.

The project contains no `removeItemAtPath:`, `rm -rf`, `system()`, `posix_spawn`, or `NSTask` deletion path.

## Path confinement

Before cleaning an App, `SafetyPolicy` resolves and validates its data container and re-reads `.com.apple.mobile_container_manager.metadata.plist` to confirm that the current `MCMMetadataIdentifier` still equals the scanned Bundle ID.

The cleaner then opens the container and walks only hard-coded relative components:

- `Library` → `Caches`
- optionally `tmp`

All directory opens use `O_NOFOLLOW`. Child metadata is read using `fstatat(..., AT_SYMLINK_NOFOLLOW)`. Symbolic links are skipped.

## User-data exclusions

The cleaner implementation contains no references to:

- Documents
- Application Support
- Preferences

No arbitrary path can be supplied from the UI.

## Privilege boundary

Entitlements include unsandboxed/AppDataContainers access required for the intended TrollStore use case, but intentionally omit root helper/persona management privileges.

## Automated checks performed for this revision

- `scripts/static_audit.sh`: PASS
- host POSIX symlink escape test: PASS
- plist parse: PASS
- bundle identifier consistency: PASS

## Remaining verification

This environment does not provide an iOS SDK, so Objective-C/UIKit compilation and real-device TrollStore behavior are not yet verified here. The included GitHub Actions workflow performs a real Theos/iOS build before producing the TIPA artifact.
