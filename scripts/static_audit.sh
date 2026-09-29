#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

while IFS= read -r -d '' file; do
    if grep -nE 'removeItemAtPath|unlinkat\(|unlink\(|rmdir\(|remove\(' "$file"; then
        echo "ERROR: destructive filesystem call found outside CacheCleaner.m: $file"
        exit 1
    fi
done < <(find SafeCache -type f ! -name 'CacheCleaner.m' -print0)

if grep -RInE 'persona-mgmt|posix_spawn|system\(|NSTask|platform-application|skip-library-validation|dynamic-codesigning|cs.debugger' SafeCache SafeCache.entitlements; then
    echo "ERROR: forbidden privilege/execution entitlement or primitive found"
    exit 1
fi

if grep -nE 'Documents|Application Support|Preferences' SafeCache/CacheCleaner.m; then
    echo "ERROR: cleaner references protected user-data directory"
    exit 1
fi

count=$(grep -c 'unlinkat(' SafeCache/CacheCleaner.m || true)
if [ "$count" -ne 2 ]; then
    echo "ERROR: expected exactly 2 unlinkat call sites, found $count"
    exit 1
fi

grep -q 'O_NOFOLLOW' SafeCache/CacheCleaner.m
grep -q 'AT_SYMLINK_NOFOLLOW' SafeCache/CacheCleaner.m
grep -q 'com.apple.private.security.no-sandbox' SafeCache.entitlements

# Least privilege: no unrestricted-container entitlement is embedded in v0.4.
if grep -q 'com.apple.private.security.storage.AppDataContainers' SafeCache.entitlements; then
    echo "ERROR: AppDataContainers entitlement unexpectedly present"
    exit 1
fi

echo "PASS: SafeCache static safety audit"
