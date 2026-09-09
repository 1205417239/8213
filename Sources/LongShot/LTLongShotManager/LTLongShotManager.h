// LTLongShotManager.h
// Long (scrolling) screenshot module: repeatedly captures frames via
// LTScreenshotManager while the caller programmatically scrolls the
// target scroll view, then stitches the frames into one tall image.
//
// Extension point: -stitchFrames: uses simple vertical concatenation
// with a fixed overlap trim; swap in template-matching-based overlap
// detection later without changing the public capture API.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^LTLongShotProgress)(NSInteger framesCaptured);
typedef void (^LTLongShotCompletion)(UIImage * _Nullable stitchedImage, NSError * _Nullable error);

@interface LTLongShotManager : NSObject <LTModule>

+ (instancetype)sharedManager;

@property (nonatomic, assign, readonly) BOOL isCapturing;
// Pixel height trimmed from the overlapping edge between consecutive
// frames; tune per-app if a status/nav bar is re-captured each frame.
@property (nonatomic, assign) CGFloat overlapTrim;

// Starts a capture session bound to `scrollView`. The caller is
// responsible for driving scrollView's contentOffset between calls to
// -captureNextFrame; this manager only captures + stitches.
- (void)beginSessionWithScrollView:(UIScrollView *)scrollView;

// Captures the current frame of the bound scroll view.
- (void)captureNextFrameWithProgress:(nullable LTLongShotProgress)progress;

// Finishes the session, stitching all captured frames.
- (void)finishSessionWithCompletion:(LTLongShotCompletion)completion;

- (void)cancelSession;

@end

NS_ASSUME_NONNULL_END
