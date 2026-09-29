#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Destructive operations must exist only in CacheCleaner.m.
if grep -RInE 'removeItemAtPath|unlinkat\(|unlink\(|rmdir\(|remove\(' SafeCache --exclude=CacheCleaner.m; then
  echo "ERROR: destructive filesystem call found outside CacheCleaner.m"
  exit 1
fi

# Root helper / arbitrary shell execution are intentionally forbidden.
if grep -RInE 'persona-mgmt|posix_spawn|system\(|NSTask' SafeCache SafeCache.entitlements; then
  echo "ERROR: forbidden privilege/execution primitive found"
  exit 1
fi

# Ensure cleaner source never references user-data directories as deletion targets.
if grep -nE 'Documents|Application Support|Preferences' SafeCache/CacheCleaner.m; then
  echo "ERROR: cleaner references protected user-data directory"
  exit 1
fi

# The only intended delete primitive is unlinkat using directory FDs.
count=$(grep -c 'unlinkat(' SafeCache/CacheCleaner.m || true)
if [ "$count" -ne 2 ]; then
  echo "ERROR: expected exactly 2 unlinkat call sites, found $count"
  exit 1
fi

grep -q 'O_NOFOLLOW' SafeCache/CacheCleaner.m
grep -q 'AT_SYMLINK_NOFOLLOW' SafeCache/CacheCleaner.m
grep -q 'com.apple.private.security.no-sandbox' SafeCache.entitlements
grep -q 'com.apple.private.security.storage.AppDataContainers' SafeCache.entitlements

echo "PASS: SafeCache static safety audit"
