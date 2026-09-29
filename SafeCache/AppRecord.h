#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppRecord : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *containerPath;
@property (nonatomic) unsigned long long cacheBytes;
@property (nonatomic) unsigned long long tmpBytes;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL whitelisted;
@end

NS_ASSUME_NONNULL_END
