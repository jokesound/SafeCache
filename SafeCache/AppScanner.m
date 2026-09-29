#import "AppScanner.h"
#import "AppRecord.h"
#import "SafetyPolicy.h"
#include <sys/stat.h>

@implementation AppScanner

+ (unsigned long long)allocatedSizeAtPath:(NSString *)path {
    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:path isDirectory:&isDir]) return 0;

    if (!isDir) {
        NSDictionary *a = [fm attributesOfItemAtPath:path error:nil];
        return [a[NSFileSize] unsignedLongLongValue];
    }

    unsigned long long total = 0;
    NSDirectoryEnumerator *en = [fm enumeratorAtURL:[NSURL fileURLWithPath:path]
                         includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLFileAllocatedSizeKey, NSURLTotalFileAllocatedSizeKey, NSURLIsSymbolicLinkKey]
                                            options:0
                                       errorHandler:^BOOL(NSURL *url, NSError *error) { return YES; }];
    for (NSURL *url in en) {
        NSNumber *isLink = nil;
        [url getResourceValue:&isLink forKey:NSURLIsSymbolicLinkKey error:nil];
        if (isLink.boolValue) {
            [en skipDescendants];
            continue;
        }
        NSNumber *isRegular = nil;
        [url getResourceValue:&isRegular forKey:NSURLIsRegularFileKey error:nil];
        if (!isRegular.boolValue) continue;
        NSNumber *size = nil;
        [url getResourceValue:&size forKey:NSURLTotalFileAllocatedSizeKey error:nil];
        if (!size) [url getResourceValue:&size forKey:NSURLFileAllocatedSizeKey error:nil];
        total += size.unsignedLongLongValue;
    }
    return total;
}

- (NSDictionary<NSString *, NSDictionary *> *)bundleInfoByID {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray<NSString *> *roots = @[@"/var/containers/Bundle/Application", @"/private/var/containers/Bundle/Application"];
    for (NSString *root in roots) {
        NSArray *uuidDirs = [fm contentsOfDirectoryAtPath:root error:nil];
        if (!uuidDirs) continue;
        for (NSString *uuid in uuidDirs) {
            NSString *uuidPath = [root stringByAppendingPathComponent:uuid];
            NSArray *items = [fm contentsOfDirectoryAtPath:uuidPath error:nil];
            for (NSString *item in items) {
                if (![item.pathExtension.lowercaseString isEqualToString:@"app"]) continue;
                NSString *plistPath = [[uuidPath stringByAppendingPathComponent:item] stringByAppendingPathComponent:@"Info.plist"];
                NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:plistPath];
                NSString *bid = info[@"CFBundleIdentifier"];
                if (bid.length == 0) continue;
                NSString *name = info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"] ?: bid;
                result[bid] = @{ @"name": name };
            }
        }
        if (result.count > 0) break;
    }
    return result;
}

- (NSArray<AppRecord *> *)scanAppsIncludeTmp:(BOOL)includeTmp whitelist:(NSSet<NSString *> *)whitelist {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSDictionary *bundleMap = [self bundleInfoByID];
    NSString *dataRoot = @"/var/mobile/Containers/Data/Application";
    NSArray<NSString *> *uuids = [fm contentsOfDirectoryAtPath:dataRoot error:nil] ?: @[];
    NSMutableArray<AppRecord *> *apps = [NSMutableArray array];

    for (NSString *uuid in uuids) {
        @autoreleasepool {
            NSString *container = [dataRoot stringByAppendingPathComponent:uuid];
            NSString *metaPath = [container stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];
            NSDictionary *meta = [NSDictionary dictionaryWithContentsOfFile:metaPath];
            NSString *bid = meta[@"MCMMetadataIdentifier"];
            if (bid.length == 0) continue;
            if ([bid hasPrefix:@"com.apple."]) continue;
            if ([bid isEqualToString:@"com.safecache.cleaner"]) continue;
            NSDictionary *bundle = bundleMap[bid];
            if (!bundle) continue;
            if (![SafetyPolicy isValidAppContainer:container bundleID:bid]) continue;

            AppRecord *r = [AppRecord new];
            r.bundleID = bid;
            r.name = bundle[@"name"] ?: bid;
            r.containerPath = container;
            NSString *cachePath = [container stringByAppendingPathComponent:@"Library/Caches"];
            NSString *tmpPath = [container stringByAppendingPathComponent:@"tmp"];
            r.cacheBytes = [SafetyPolicy isAllowedBaseDirectory:cachePath container:container] ? [AppScanner allocatedSizeAtPath:cachePath] : 0;
            r.tmpBytes = (includeTmp && [SafetyPolicy isAllowedBaseDirectory:tmpPath container:container]) ? [AppScanner allocatedSizeAtPath:tmpPath] : 0;
            r.whitelisted = [whitelist containsObject:bid];
            r.selected = NO;
            [apps addObject:r];
        }
    }

    [apps sortUsingComparator:^NSComparisonResult(AppRecord *a, AppRecord *b) {
        unsigned long long sa = a.cacheBytes + a.tmpBytes;
        unsigned long long sb = b.cacheBytes + b.tmpBytes;
        if (sa == sb) return [a.name localizedCaseInsensitiveCompare:b.name];
        return sa > sb ? NSOrderedAscending : NSOrderedDescending;
    }];
    return apps;
}

@end
