// LTManager.h
// Core coordinator: preference loading, Darwin notification reload,
// and a lightweight module-registry protocol so each feature manager
// (Freeze / Screenshot / Translate / AI / Editor / LongShot / Sileo)
// can register itself and be enabled/disabled independently.
//
// Extension point: add new keys to LTManager+prefsDictionary and a new
// LTModuleXXX enum case to register additional modules without touching
// existing manager code.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kLTPrefsDomain;     // com.lingua.tweak
extern NSString * const kLTPrefsPath;       // full plist path
extern NSString * const kLTReloadNotify;    // darwin notify name

// Conform to this from every LTXxxManager to plug into LTManager's
// lifecycle (enable/disable/reload) without LTManager needing to know
// concrete manager types.
@protocol LTModule <NSObject>
@required
- (void)activate;      // install hooks / observers
- (void)deactivate;    // tear down, called when user disables module in prefs
@optional
- (void)reloadPreferences; // called after user changes settings
@end

@interface LTManager : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id> *prefs;
@property (nonatomic, strong, readonly) NSMutableArray<id<LTModule>> *modules;

+ (instancetype)sharedManager;

// Preferences
- (void)reloadPreferences;
- (BOOL)boolForKey:(NSString *)key default:(BOOL)defaultValue;
- (nullable NSString *)stringForKey:(NSString *)key default:(nullable NSString *)defaultValue;

// Module registry — extension point for new features.
- (void)registerModule:(id<LTModule>)module;
- (void)activateAllModules;

// Convenience top-level toggle
- (BOOL)isTweakEnabled;

@end

NS_ASSUME_NONNULL_END
