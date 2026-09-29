#import "SafetyPolicy.h"
#import <sys/stat.h>
#import <limits.h>
#import <stdlib.h>

@implementation SafetyPolicy

+ (NSString *)std:(NSString *)path {
    return path.stringByStandardizingPath;
}

+ (nullable NSString *)resolvedExistingPath:(NSString *)path {
    char resolved[PATH_MAX];
    if (!realpath(path.fileSystemRepresentation, resolved)) return nil;
    return [NSString stringWithUTF8String:resolved];
}

+ (BOOL)isValidAppContainer:(NSString *)container bundleID:(NSString *)bundleID {
    if (container.length == 0 || bundleID.length == 0) return NO;

    NSString *root = @"/var/mobile/Containers/Data/Application";
    NSString *resolvedRoot = [self resolvedExistingPath:root];
    NSString *resolvedContainer = [self resolvedExistingPath:container];
    if (!resolvedRoot || !resolvedContainer) return NO;

    NSString *prefix = [resolvedRoot stringByAppendingString:@"/"];
    if (![resolvedContainer hasPrefix:prefix]) return NO;

    NSString *relative = [resolvedContainer substringFromIndex:prefix.length];
    if (relative.length == 0 || [relative containsString:@"/"]) return NO;

    struct stat st;
    if (lstat(resolvedContainer.fileSystemRepresentation, &st) != 0) return NO;
    if (!S_ISDIR(st.st_mode) || S_ISLNK(st.st_mode)) return NO;

    NSString *metaPath = [resolvedContainer stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];
    NSDictionary *meta = [NSDictionary dictionaryWithContentsOfFile:metaPath];
    NSString *currentBundleID = meta[@"MCMMetadataIdentifier"];
    if (![currentBundleID isKindOfClass:NSString.class] || ![currentBundleID isEqualToString:bundleID]) return NO;

    return YES;
}

+ (BOOL)isAllowedBaseDirectory:(NSString *)base container:(NSString *)container {
    if (base.length == 0 || container.length == 0) return NO;
    NSString *c = [self std:container];
    NSString *b = [self std:base];
    NSString *cache = [[c stringByAppendingPathComponent:@"Library/Caches"] stringByStandardizingPath];
    NSString *tmp = [[c stringByAppendingPathComponent:@"tmp"] stringByStandardizingPath];
    BOOL exactAllowedPath = [b isEqualToString:cache] || [b isEqualToString:tmp];
    if (!exactAllowedPath) return NO;

    // If the directory exists, also resolve it. This prevents even read-only scans
    // from wandering through a symlinked Library/Caches or tmp path.
    if ([NSFileManager.defaultManager fileExistsAtPath:b]) {
        NSString *resolvedContainer = [self resolvedExistingPath:c];
        NSString *resolvedBase = [self resolvedExistingPath:b];
        if (!resolvedContainer || !resolvedBase) return NO;
        NSString *suffix = [b isEqualToString:cache] ? @"Library/Caches" : @"tmp";
        NSString *expected = [[resolvedContainer stringByAppendingPathComponent:suffix] stringByStandardizingPath];
        if (![resolvedBase isEqualToString:expected]) return NO;

        struct stat st;
        if (lstat(b.fileSystemRepresentation, &st) != 0 || !S_ISDIR(st.st_mode) || S_ISLNK(st.st_mode)) return NO;
    }
    return YES;
}

+ (BOOL)isSymbolicLinkAtPath:(NSString *)path {
    struct stat st;
    if (lstat(path.fileSystemRepresentation, &st) != 0) return NO;
    return S_ISLNK(st.st_mode);
}

@end
