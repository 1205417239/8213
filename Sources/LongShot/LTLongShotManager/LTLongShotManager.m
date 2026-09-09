// LTLongShotManager.m
#import "LTLongShotManager.h"
#import "LTScreenshotManager.h"

@interface LTLongShotManager ()
@property (nonatomic, weak) UIScrollView *targetScrollView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *frames;
@property (nonatomic, assign) BOOL isCapturing;
// Fix: private selector called in -finishSessionWithCompletion: before definition.
- (nullable UIImage *)stitchFrames:(NSArray<UIImage *> *)frames;
@end

@implementation LTLongShotManager

+ (instancetype)sharedManager {
	static LTLongShotManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTLongShotManager alloc] init]; });
	return shared;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_frames = [NSMutableArray array];
		_overlapTrim = 0.0;
	}
	return self;
}

#pragma mark - LTModule

- (void)activate {}
- (void)deactivate { [self cancelSession]; }

#pragma mark - Public

- (void)beginSessionWithScrollView:(UIScrollView *)scrollView {
	[self.frames removeAllObjects];
	self.targetScrollView = scrollView;
	self.isCapturing = YES;
}

- (void)captureNextFrameWithProgress:(nullable LTLongShotProgress)progress {
	if (!self.isCapturing) return;
	UIScrollView *scrollView = self.targetScrollView;
	if (!scrollView) return;

	CGRect frameInWindow = [scrollView convertRect:scrollView.bounds toView:nil];
	[[LTScreenshotManager sharedManager] captureRegion:frameInWindow completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
		if (image) {
			[self.frames addObject:image];
		}
		if (progress) {
			progress(self.frames.count);
		}
	}];
}

- (void)finishSessionWithCompletion:(LTLongShotCompletion)completion {
	self.isCapturing = NO;
	if (self.frames.count == 0) {
		NSError *error = [NSError errorWithDomain:@"LTLongShotManager" code:1
			userInfo:@{NSLocalizedDescriptionKey: @"No frames captured"}];
		completion(nil, error);
		return;
	}
	UIImage *stitched = [self stitchFrames:self.frames];
	completion(stitched, nil);
}

- (void)cancelSession {
	self.isCapturing = NO;
	[self.frames removeAllObjects];
	self.targetScrollView = nil;
}

#pragma mark - Stitching

- (nullable UIImage *)stitchFrames:(NSArray<UIImage *> *)frames {
	if (frames.count == 0) return nil;
	if (frames.count == 1) return frames.firstObject;

	CGFloat width = frames.firstObject.size.width;
	CGFloat totalHeight = 0;
	for (UIImage *frame in frames) {
		totalHeight += (frame.size.height - self.overlapTrim);
	}
	totalHeight += self.overlapTrim; // restore trim for the final frame

	CGSize canvasSize = CGSizeMake(width, totalHeight);

	UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
	format.opaque = YES;
	UIGraphicsImageRenderer *renderer =
		[[UIGraphicsImageRenderer alloc] initWithSize:canvasSize format:format];

	return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull ctx) {
		CGFloat y = 0;
		for (UIImage *frame in frames) {
			[frame drawAtPoint:CGPointMake(0, y)];
			y += (frame.size.height - self.overlapTrim);
		}
	}];
}

@end
