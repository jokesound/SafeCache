#import <Foundation/Foundation.h>
@class AppRecord;

NS_ASSUME_NONNULL_BEGIN

typedef void (^CleanLogBlock)(NSString *message);

@interface CacheCleaner : NSObject
- (unsigned long long)cleanRecord:(AppRecord *)record includeTmp:(BOOL)includeTmp log:(CleanLogBlock)log;
@end

NS_ASSUME_NONNULL_END
