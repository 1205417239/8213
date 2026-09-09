// LTManager.m
#import "LTManager.h"
#import <notify.h>

NSString * const kLTPrefsDomain  = @"com.lingua.tweak";
NSString * const kLTPrefsPath    = @"/var/mobile/Library/Preferences/com.lingua.tweak.plist";
NSString * const kLTReloadNotify = @"com.lingua.tweak/prefs.reloaded";

@interface LTManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *prefs;
@property (nonatomic, strong) NSMutableArray<id<LTModule>> *modules;
@property (nonatomic, assign) int notifyToken;
// Fix: private method is called in -init before its definition below;
// declare it here so ARC/clang sees the selector at the call site.
- (void)observeReloadNotification;
@end

@implementation LTManager

+ (instancetype)sharedManager {
	static LTManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		shared = [[LTManager alloc] init];
	});
	return shared;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_modules = [NSMutableArray array];
		[self reloadPreferences];
		[self observeReloadNotification];
	}
	return self;
}

- (void)observeReloadNotification {
	__weak typeof(self) weakSelf = self;
	notify_register_dispatch(kLTReloadNotify.UTF8String, &_notifyToken,
		dispatch_get_main_queue(), ^(int token) {
			[weakSelf reloadPreferences];
			for (id<LTModule> module in weakSelf.modules) {
				if ([module respondsToSelector:@selector(reloadPreferences)]) {
					[module reloadPreferences];
				}
			}
		});
}

- (void)reloadPreferences {
	NSDictionary *onDisk = [NSDictionary dictionaryWithContentsOfFile:kLTPrefsPath];
	_prefs = onDisk ? [onDisk mutableCopy] : [NSMutableDictionary dictionary];
}

- (BOOL)boolForKey:(NSString *)key default:(BOOL)defaultValue {
	id value = self.prefs[key];
	if (value == nil) return defaultValue;
	return [value boolValue];
}

- (nullable NSString *)stringForKey:(NSString *)key default:(nullable NSString *)defaultValue {
	id value = self.prefs[key];
	if (![value isKindOfClass:[NSString class]]) return defaultValue;
	return value;
}

- (BOOL)isTweakEnabled {
	return [self boolForKey:@"Enabled" default:YES];
}

- (void)registerModule:(id<LTModule>)module {
	[self.modules addObject:module];
}

- (void)activateAllModules {
	if (![self isTweakEnabled]) return;
	for (id<LTModule> module in self.modules) {
		[module activate];
	}
}

@end
