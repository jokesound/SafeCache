#import <Foundation/Foundation.h>
@class AppRecord;

NS_ASSUME_NONNULL_BEGIN

@interface AppScanner : NSObject
- (NSArray<AppRecord *> *)scanAppsIncludeTmp:(BOOL)includeTmp whitelist:(NSSet<NSString *> *)whitelist;
+ (unsigned long long)allocatedSizeAtPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
