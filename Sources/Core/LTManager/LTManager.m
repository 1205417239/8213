#import "LTManager.h"
#import <notify.h>

NSString * const kLTPrefsDomain = @"com.lingua.tweak";
NSString * const kLTPrefsPath = @"/var/mobile/Library/Preferences/com.lingua.tweak.plist";
NSString * const kLTReloadNotify = @"com.lingua.tweak/prefs.reloaded";

@interface LTManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *prefs;
@property (nonatomic, strong) NSMutableArray<id<LTModule>> *modules;
@property (nonatomic, assign) int notifyToken;
- (void)observeReloadNotification;
@end

@implementation LTManager

+ (instancetype)sharedManager {
    static LTManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _modules = [NSMutableArray array];
        _prefs = [NSMutableDictionary dictionary];
        [self reloadPreferences];
        [self observeReloadNotification];
    }
    return self;
}

- (void)observeReloadNotification {
    __weak typeof(self) weakSelf = self;

    notify_register_dispatch(kLTReloadNotify.UTF8String,
                             &_notifyToken,
                             dispatch_get_main_queue(),
                             ^(int token) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        [self reloadPreferences];

        for (id<LTModule> module in self.modules) {
            if ([module respondsToSelector:@selector(reloadPreferences)]) {
                [module reloadPreferences];
            }
        }
    });
}

- (void)reloadPreferences {
    NSDictionary *diskPrefs =
        [NSDictionary dictionaryWithContentsOfFile:kLTPrefsPath];

    if ([diskPrefs isKindOfClass:[NSDictionary class]]) {
        self.prefs = [diskPrefs mutableCopy];
    } else {
        self.prefs = [NSMutableDictionary dictionary];
    }
}

- (BOOL)boolForKey:(NSString *)key
           default:(BOOL)defaultValue {

    id value = self.prefs[key];

    if (!value) {
        return defaultValue;
    }

    return [value boolValue];
}

- (nullable NSString *)stringForKey:(NSString *)key
                            default:(nullable NSString *)defaultValue {

    id value = self.prefs[key];

    if (![value isKindOfClass:[NSString class]]) {
        return defaultValue;
    }

    return value;
}

- (BOOL)isTweakEnabled {
    return [self boolForKey:@"Enabled" default:YES];
}

- (void)registerModule:(id<LTModule>)module {
    if (!module) {
        return;
    }

    if (![self.modules containsObject:module]) {
        [self.modules addObject:module];
    }
}

- (void)activateAllModules {
    if (![self isTweakEnabled]) {
        return;
    }

    for (id<LTModule> module in [self.modules copy]) {
        if ([module respondsToSelector:@selector(activate)]) {
            [module activate];
        }
    }
}

@end
