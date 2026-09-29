#import "CacheCleaner.h"
#import "AppRecord.h"
#import "SafetyPolicy.h"
#import "AppScanner.h"
#import <sys/stat.h>
#import <fcntl.h>
#import <dirent.h>
#import <unistd.h>
#import <errno.h>
#import <string.h>

@implementation CacheCleaner

// Deletes only entries reachable through an already-open directory FD.
// Symlinks are never followed or removed. Directories are opened with O_NOFOLLOW.
- (BOOL)cleanDirectoryFD:(int)dirFD log:(CleanLogBlock)log {
    int dupFD = dup(dirFD);
    if (dupFD < 0) {
        if (log) log(@"无法读取缓存目录，已安全跳过。");
        return NO;
    }

    DIR *dir = fdopendir(dupFD);
    if (!dir) {
        close(dupFD);
        if (log) log(@"无法打开缓存目录，已安全跳过。");
        return NO;
    }

    BOOL ok = YES;
    struct dirent *entry = NULL;
    while ((entry = readdir(dir)) != NULL) {
        const char *name = entry->d_name;
        if (strcmp(name, ".") == 0 || strcmp(name, "..") == 0) continue;

        struct stat st;
        if (fstatat(dirFD, name, &st, AT_SYMLINK_NOFOLLOW) != 0) {
            ok = NO;
            continue;
        }

        NSString *displayName = [NSString stringWithUTF8String:name] ?: @"未知项目";

        if (S_ISLNK(st.st_mode)) {
            if (log) log([NSString stringWithFormat:@"跳过符号链接：%@", displayName]);
            ok = NO;
            continue;
        }

        if (S_ISDIR(st.st_mode)) {
            int childFD = openat(dirFD, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
            if (childFD < 0) {
                if (log) log([NSString stringWithFormat:@"跳过无法安全打开的目录：%@", displayName]);
                ok = NO;
                continue;
            }
            BOOL childOK = [self cleanDirectoryFD:childFD log:log];
            close(childFD);
            if (childOK) {
                if (unlinkat(dirFD, name, AT_REMOVEDIR) != 0 && errno != ENOENT && errno != ENOTEMPTY) {
                    if (log) log([NSString stringWithFormat:@"目录删除失败：%@", displayName]);
                    ok = NO;
                }
            } else {
                ok = NO;
            }
            continue;
        }

        // Conservative by design: only regular files are removed.
        // Sockets/FIFOs/devices or any unusual filesystem object are left untouched.
        if (!S_ISREG(st.st_mode)) {
            if (log) log([NSString stringWithFormat:@"跳过非常规文件：%@", displayName]);
            ok = NO;
            continue;
        }

        if (unlinkat(dirFD, name, 0) != 0 && errno != ENOENT) {
            if (log) log([NSString stringWithFormat:@"文件删除失败：%@", displayName]);
            ok = NO;
        }
    }

    closedir(dir);
    return ok;
}

- (unsigned long long)cleanCacheForContainerFD:(int)containerFD
                                  containerPath:(NSString *)containerPath
                                    includeTmp:(BOOL)includeTmp
                                           log:(CleanLogBlock)log {
    unsigned long long freed = 0;

    // Open Library -> Caches one component at a time with O_NOFOLLOW.
    // A symlinked Library or Caches component therefore fails closed.
    int libraryFD = openat(containerFD, "Library", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (libraryFD >= 0) {
        int cacheFD = openat(libraryFD, "Caches", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        if (cacheFD >= 0) {
            NSString *cachePath = [containerPath stringByAppendingPathComponent:@"Library/Caches"];
            unsigned long long before = [AppScanner allocatedSizeAtPath:cachePath];
            [self cleanDirectoryFD:cacheFD log:log];
            unsigned long long after = [AppScanner allocatedSizeAtPath:cachePath];
            if (before > after) freed += (before - after);
            close(cacheFD);
        } else if (errno != ENOENT && log) {
            log(@"Library/Caches 无法以无符号链接模式打开，已跳过。");
        }
        close(libraryFD);
    } else if (errno != ENOENT && log) {
        log(@"Library 无法以无符号链接模式打开，已跳过缓存清理。");
    }

    if (includeTmp) {
        int tmpFD = openat(containerFD, "tmp", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        if (tmpFD >= 0) {
            NSString *tmpPath = [containerPath stringByAppendingPathComponent:@"tmp"];
            unsigned long long before = [AppScanner allocatedSizeAtPath:tmpPath];
            [self cleanDirectoryFD:tmpFD log:log];
            unsigned long long after = [AppScanner allocatedSizeAtPath:tmpPath];
            if (before > after) freed += (before - after);
            close(tmpFD);
        } else if (errno != ENOENT && log) {
            log(@"tmp 无法以无符号链接模式打开，已跳过。");
        }
    }

    return freed;
}

- (unsigned long long)cleanRecord:(AppRecord *)record includeTmp:(BOOL)includeTmp log:(CleanLogBlock)log {
    if (record.whitelisted) {
        if (log) log([NSString stringWithFormat:@"%@ 在白名单中，已跳过。", record.name]);
        return 0;
    }
    if (record.containerPath.length == 0 || record.bundleID.length == 0) return 0;

    // Re-validate immediately before deletion. A stale result after reinstall/update is refused.
    if (![SafetyPolicy isValidAppContainer:record.containerPath bundleID:record.bundleID]) {
        if (log) log([NSString stringWithFormat:@"%@ 的容器身份校验失败，已跳过。", record.name]);
        return 0;
    }

    int containerFD = open(record.containerPath.fileSystemRepresentation, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (containerFD < 0) {
        if (log) log([NSString stringWithFormat:@"%@ 的数据容器无法安全打开，已跳过。", record.name]);
        return 0;
    }

    unsigned long long freed = [self cleanCacheForContainerFD:containerFD
                                                 containerPath:record.containerPath
                                                   includeTmp:includeTmp
                                                          log:log];
    close(containerFD);
    return freed;
}

@end
