#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

# 删除 API 只能存在于 CacheCleaner.m。
# 不使用 grep --exclude，避免 GNU grep / macOS BSD grep 行为差异。
while IFS= read -r -d '' file; do
    if grep -nE 'removeItemAtPath|unlinkat\(|unlink\(|rmdir\(|remove\(' "$file"; then
        echo "ERROR: destructive filesystem call found outside CacheCleaner.m: $file"
        exit 1
    fi
done < <(find SafeCache -type f ! -name 'CacheCleaner.m' -print0)

# 禁止 root helper 和任意 shell 执行。
if grep -RInE 'persona-mgmt|posix_spawn|system\(|NSTask' SafeCache SafeCache.entitlements; then
    echo "ERROR: forbidden privilege/execution primitive found"
    exit 1
fi

# 清理器禁止引用用户数据目录。
if grep -nE 'Documents|Application Support|Preferences' SafeCache/CacheCleaner.m; then
    echo "ERROR: cleaner references protected user-data directory"
    exit 1
fi

# 删除原语必须严格只有两个 unlinkat 调用点。
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
