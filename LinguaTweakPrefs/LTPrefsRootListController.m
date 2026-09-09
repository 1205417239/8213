// LTPrefsRootListController.m
// LinguaTweak preference bundle root controller.
// Reads/writes /var/mobile/Library/Preferences/com.lingua.tweak.plist
// and posts a Darwin notification so LinguaTweak.dylib can reload live.

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Foundation/Foundation.h>
#import <notify.h>

#define LT_PREFS_DOMAIN CFSTR("com.lingua.tweak/prefs.reloaded")
#define LT_RESPRING_DOMAIN "com.lingua.tweak/respring.requested"

@interface LTPrefsRootListController : PSListController
@end

@implementation LTPrefsRootListController

// Explicit designated-init override: PreferenceLoader instantiates this
// controller via -alloc/-init. Keep it side-effect free so nothing can throw
// during the load/instantiation phase.
- (instancetype)init {
	self = [super init];
	if (self) {
		// All UI is declared in Root.plist; no fragile work at init time.
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Layout/specifiers come entirely from Root.plist; nothing else to do.
}

// Lazily build the specifier list exactly once. Guard against a missing or
// unparseable Root.plist returning nil, which would otherwise leave the list
// controller in an inconsistent state.
- (NSArray *)specifiers {
	if (_specifiers == nil) {
		NSMutableArray *loaded = [self loadSpecifiersFromPlistName:@"Root" target:self];
		_specifiers = (loaded != nil) ? loaded : [NSMutableArray array];
	}
	return _specifiers;
}

// Called whenever any switch/slider bound to a PSSpecifier changes.
// Root.plist entries route here so we can broadcast a reload notification.
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];
	[self postReloadNotification];
}

- (void)postReloadNotification {
	CFNotificationCenterPostNotification(
		CFNotificationCenterGetDarwinNotifyCenter(),
		LT_PREFS_DOMAIN,
		NULL, NULL, TRUE);
}

// Hook for a future "About / Restart SpringBoard" button.
- (void)respringDevice {
	notify_post(LT_RESPRING_DOMAIN);
}

@end
