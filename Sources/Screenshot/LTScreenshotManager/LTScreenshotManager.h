// LTScreenshotManager.h
// Region + full-screen capture used by the selection toolbar's
// "capture" action, and shared by LTLongShotManager as the single-frame
// building block for stitched long screenshots.
//
// Extension point: -captureRegion:completion: currently rasterizes the
// view hierarchy; add IOSurface/CoreVideo based fast paths later behind
// the same completion-block signature.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^LTScreenshotCompletion)(UIImage * _Nullable image, NSError * _Nullable error);

@interface LTScreenshotManager : NSObject <LTModule>

+ (instancetype)sharedManager;

// Captures the full key window.
- (void)captureFullScreen:(LTScreenshotCompletion)completion;

// Captures a specific region in screen coordinates (e.g. the current
// text selection rect from the toolbar).
- (void)captureRegion:(CGRect)region completion:(LTScreenshotCompletion)completion;

// Saves an image to the Photos library, reporting success/failure.
- (void)saveImageToPhotos:(UIImage *)image completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
