#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsStore : NSObject
@property (nonatomic) BOOL includeTmp;
- (NSMutableSet<NSString *> *)whitelist;
- (void)saveWhitelist:(NSSet<NSString *> *)set;
@end

NS_ASSUME_NONNULL_END
