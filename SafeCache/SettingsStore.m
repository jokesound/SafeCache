#import "SettingsStore.h"

static NSString * const kWhitelistKey = @"SafeCacheWhitelist";
static NSString * const kIncludeTmpKey = @"SafeCacheIncludeTmp";

@implementation SettingsStore

- (instancetype)init {
    if ((self = [super init])) {
        if (![NSUserDefaults.standardUserDefaults objectForKey:kWhitelistKey]) {
            [self saveWhitelist:[NSSet setWithObject:@"com.tencent.xin"]];
        }
        _includeTmp = [NSUserDefaults.standardUserDefaults boolForKey:kIncludeTmpKey];
    }
    return self;
}

- (void)setIncludeTmp:(BOOL)includeTmp {
    _includeTmp = includeTmp;
    [NSUserDefaults.standardUserDefaults setBool:includeTmp forKey:kIncludeTmpKey];
}

- (NSMutableSet<NSString *> *)whitelist {
    NSArray *arr = [NSUserDefaults.standardUserDefaults arrayForKey:kWhitelistKey] ?: @[];
    return [NSMutableSet setWithArray:arr];
}

- (void)saveWhitelist:(NSSet<NSString *> *)set {
    NSArray *arr = [[set allObjects] sortedArrayUsingSelector:@selector(compare:)];
    [NSUserDefaults.standardUserDefaults setObject:arr forKey:kWhitelistKey];
}

@end
