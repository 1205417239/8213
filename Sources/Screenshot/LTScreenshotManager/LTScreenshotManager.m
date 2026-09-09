// LTScreenshotManager.m
#import "LTScreenshotManager.h"
#import <Photos/Photos.h>

@implementation LTScreenshotManager

+ (instancetype)sharedManager {
	static LTScreenshotManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTScreenshotManager alloc] init]; });
	return shared;
}

#pragma mark - LTModule

- (void)activate {
	// Stateless module; capture is invoked on-demand from the toolbar.
}

- (void)deactivate {
	// Nothing persistent to tear down.
}

#pragma mark - Public

- (nullable UIWindow *)currentKeyWindow {
	for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (scene.activationState == UISceneActivationStateForegroundActive) {
			for (UIWindow *w in scene.windows) {
				if (w.isKeyWindow) return w;
			}
		}
	}
	return nil;
}

- (void)captureFullScreen:(LTScreenshotCompletion)completion {
	[self captureRegion:CGRectNull completion:completion];
}

- (void)captureRegion:(CGRect)region completion:(LTScreenshotCompletion)completion {
	UIWindow *keyWindow = [self currentKeyWindow];
	if (!keyWindow) {
		NSError *error = [NSError errorWithDomain:@"LTScreenshotManager" code:1
			userInfo:@{NSLocalizedDescriptionKey: @"No key window available"}];
		completion(nil, error);
		return;
	}

	CGRect captureRect = CGRectIsNull(region) ? keyWindow.bounds : CGRectIntersection(region, keyWindow.bounds);
	if (CGRectIsEmpty(captureRect)) {
		NSError *error = [NSError errorWithDomain:@"LTScreenshotManager" code:2
			userInfo:@{NSLocalizedDescriptionKey: @"Capture region is empty"}];
		completion(nil, error);
		return;
	}

	UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
	format.opaque = NO;
	UIGraphicsImageRenderer *renderer =
		[[UIGraphicsImageRenderer alloc] initWithBounds:keyWindow.bounds format:format];

	UIImage *fullImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
		[keyWindow drawViewHierarchyInRect:keyWindow.bounds afterScreenUpdates:NO];
	}];

	if (CGRectEqualToRect(captureRect, keyWindow.bounds)) {
		completion(fullImage, nil);
		return;
	}

	CGImageRef croppedRef = CGImageCreateWithImageInRect(fullImage.CGImage,
		CGRectApplyAffineTransform(captureRect, CGAffineTransformMakeScale(fullImage.scale, fullImage.scale)));
	UIImage *cropped = [UIImage imageWithCGImage:croppedRef scale:fullImage.scale orientation:fullImage.imageOrientation];
	CGImageRelease(croppedRef);

	completion(cropped, nil);
}

- (void)saveImageToPhotos:(UIImage *)image completion:(void (^ _Nullable)(BOOL, NSError * _Nullable))completion {
	[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
		if (status != PHAuthorizationStatusAuthorized) {
			if (completion) {
				NSError *error = [NSError errorWithDomain:@"LTScreenshotManager" code:3
					userInfo:@{NSLocalizedDescriptionKey: @"Photos access not authorized"}];
				dispatch_async(dispatch_get_main_queue(), ^{ completion(NO, error); });
			}
			return;
		}
		[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
			[PHAssetChangeRequest creationRequestForAssetFromImage:image];
		} completionHandler:^(BOOL success, NSError * _Nullable error) {
			if (completion) {
				dispatch_async(dispatch_get_main_queue(), ^{ completion(success, error); });
			}
		}];
	}];
}

@end
