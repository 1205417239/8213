// LTFreezeManager.h
// "Freeze" module: snapshots the current screen into a still overlay
// window so the user can take their time inspecting / selecting text
// on a screen that would otherwise auto-scroll, animate, or dismiss
// (video players, stories, toasts, etc).
//
// Extension point: -freezeCurrentScreen currently rasterizes the key
// window; swap in a lower-level IOSurface capture later without
// changing the public interface.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTFreezeManager : NSObject <LTModule>

+ (instancetype)sharedManager;

@property (nonatomic, assign, readonly, getter=isFrozen) BOOL frozen;

// Captures the current key window into a still image and presents it
// full-screen, blocking underlying interaction/animation.
- (void)freezeCurrentScreen;

// Removes the frozen overlay and resumes live interaction.
- (void)unfreeze;

- (void)toggleFreeze;

@end

NS_ASSUME_NONNULL_END
