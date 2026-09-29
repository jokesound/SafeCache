#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SafetyPolicy : NSObject
+ (BOOL)isValidAppContainer:(NSString *)container bundleID:(NSString *)bundleID;
+ (BOOL)isAllowedBaseDirectory:(NSString *)base container:(NSString *)container;
+ (BOOL)isSymbolicLinkAtPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
