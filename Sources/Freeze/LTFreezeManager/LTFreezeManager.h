// LTFreezeManager.h
// "Freeze" module: snapshots the current screen into a still overlay
// window so the user can take their time selecting a region, then
// route that region to Screenshot / OCR / Translate / AI / Editor /
// LongShot / QR modules via the floating toolbar.
//
// Call chain (first phase):
//   GlobalTrigger (SpringBoard) -> LTFreezeManager startFreeze
//     -> snapshot screen -> create UIWindow -> show frozen image
//     -> enter RegionSelect mode (default) -> show Toolbar
//
// Extension point: -snapshotOfKeyWindow currently rasterizes the key
// window via drawViewHierarchy; swap in IOSurface capture later without
// changing the public interface.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"
#import "LTRegionSelectView.h"
#import "LTToolbarView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTFreezeManager : NSObject <LTModule>

+ (instancetype)sharedManager;

@property (nonatomic, assign, readonly, getter=isFrozen) BOOL frozen;

// Currently selected region in screen coordinates. Updated live as the
// user drags the region or its handles inside the freeze overlay.
@property (nonatomic, assign, readonly) CGRect selectedRegion;

// The full-screen snapshot captured when startFreeze was called.
@property (nonatomic, strong, readonly, nullable) UIImage *frozenSnapshot;

// Captures the current key window into a still image, presents a
// full-screen overlay window, and enters region-selection mode with
// the action toolbar visible.
- (void)startFreeze;

// Removes the frozen overlay, region selector, and toolbar; resumes
// live interaction.
- (void)stopFreeze;

// Convenience toggle used by the in-app text-selection toolbar.
- (void)toggleFreeze;

// Crops the frozen snapshot to the current selectedRegion. Returns nil
// if not frozen or the region is empty.
- (nullable UIImage *)imageForSelectedRegion;

@end

NS_ASSUME_NONNULL_END
