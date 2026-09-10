// LTFreezeManager.m
#import "LTFreezeManager.h"
#import "LTScreenshotManager.h"
#import "LTTranslateManager.h"
#import "LTAIManager.h"
#import "LTEditorManager.h"
#import "LTLongShotManager.h"
#import "LTOCRManager.h"
#import "LTTranslatePanel.h"

@interface LTFreezeManager ()
@property (nonatomic, strong) UIWindow *freezeWindow;
@property (nonatomic, strong) UIImageView *freezeImageView;
@property (nonatomic, strong) LTRegionSelectView *regionSelectView;
@property (nonatomic, strong) LTToolbarView *toolbar;
@property (nonatomic, strong) UIImage *frozenSnapshot;
@property (nonatomic, assign) CGRect selectedRegion;
@property (nonatomic, assign) BOOL frozen;
// Forward-declare private helpers
- (UIWindowScene *)activeScene;
- (void)buildAndShowToolbar;
- (void)handleScreenshotAction;
- (void)handleTranslateAction;
- (void)handleAIAction;
- (void)handleEditorAction;
- (void)handleLongShotAction;
- (void)handleQRAction;
- (void)handleCloseAction;
@end

@implementation LTFreezeManager

+ (instancetype)sharedManager {
	static LTFreezeManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTFreezeManager alloc] init]; });
	return shared;
}

#pragma mark - LTModule

- (void)activate {
	// No persistent hooks at rest; freeze is invoked on-demand from
	// the SpringBoard global trigger (Tweak.x) or the in-app toolbar.
}

- (void)deactivate {
	[self stopFreeze];
}

#pragma mark - Helpers

- (UIWindowScene *)activeScene {
	for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (scene.activationState == UISceneActivationStateForegroundActive) {
			return scene;
		}
	}
	return nil;
}

- (UIImage *)snapshotOfKeyWindow {
	UIWindow *keyWindow = nil;
	UIWindowScene *scene = [self activeScene];
	if (!scene) return nil;
	for (UIWindow *w in scene.windows) {
		if (w.isKeyWindow) { keyWindow = w; break; }
	}
	if (!keyWindow) return nil;

	UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
	format.opaque = YES;
	UIGraphicsImageRenderer *renderer =
		[[UIGraphicsImageRenderer alloc] initWithBounds:keyWindow.bounds format:format];

	return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
		[keyWindow drawViewHierarchyInRect:keyWindow.bounds afterScreenUpdates:NO];
	}];
}

#pragma mark - Public

- (void)startFreeze {
	if (self.frozen) return;

	UIImage *snapshot = [self snapshotOfKeyWindow];
	if (!snapshot) return;

	UIWindowScene *scene = [self activeScene];
	if (!scene) return;

	self.frozenSnapshot = snapshot;

	// Create independent overlay window
	self.freezeWindow = [[UIWindow alloc] initWithWindowScene:scene];
	self.freezeWindow.windowLevel = UIWindowLevelStatusBar + 1;
	self.freezeWindow.backgroundColor = UIColor.blackColor;
	self.freezeWindow.frame = scene.coordinateSpace.bounds;

	// Frozen image
	self.freezeImageView = [[UIImageView alloc] initWithFrame:self.freezeWindow.bounds];
	self.freezeImageView.image = snapshot;
	self.freezeImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.freezeImageView.userInteractionEnabled = YES;
	[self.freezeWindow addSubview:self.freezeImageView];

	// Default region: centered, 70% width, 50% height
	CGRect bounds = self.freezeWindow.bounds;
	CGRect defaultRegion = CGRectMake(
		bounds.size.width * 0.15,
		bounds.size.height * 0.25,
		bounds.size.width * 0.70,
		bounds.size.height * 0.50
	);
	self.selectedRegion = defaultRegion;

	// Region select overlay
	self.regionSelectView = [[LTRegionSelectView alloc]
		initWithFrame:bounds
		initialRegion:defaultRegion];
	__weak typeof(self) weakSelf = self;
	self.regionSelectView.regionDidChangeBlock = ^(CGRect region) {
		weakSelf.selectedRegion = region;
	};
	[self.freezeWindow addSubview:self.regionSelectView];

	self.freezeWindow.hidden = NO;
	self.frozen = YES;

	// Show toolbar after a short delay so the window is ready
	dispatch_async(dispatch_get_main_queue(), ^{
		[self buildAndShowToolbar];
	});
}

- (void)stopFreeze {
	if (!self.frozen) return;

	[UIView animateWithDuration:0.2 animations:^{
		self.freezeWindow.alpha = 0;
	} completion:^(BOOL finished) {
		self.freezeWindow.hidden = YES;
		self.freezeWindow = nil;
		self.freezeImageView = nil;
		self.regionSelectView = nil;
		self.toolbar = nil;
		self.frozenSnapshot = nil;
	}];
	self.frozen = NO;
}

- (void)toggleFreeze {
	if (self.frozen) {
		[self stopFreeze];
	} else {
		[self startFreeze];
	}
}

- (nullable UIImage *)imageForSelectedRegion {
	if (!self.frozenSnapshot || CGRectIsEmpty(self.selectedRegion)) return nil;

	CGRect screenBounds = self.freezeWindow.bounds;
	CGFloat scale = self.frozenSnapshot.scale;
	// Convert from screen points to image pixels, accounting for aspect fit
	CGSize imageSize = self.frozenSnapshot.size;
	CGSize screenSize = screenBounds.size;

	// Calculate aspect-fit scaling
	CGFloat scaleX = screenSize.width / imageSize.width;
	CGFloat scaleY = screenSize.height / imageSize.height;
	CGFloat fitScale = MIN(scaleX, scaleY);
	CGSize scaledSize = CGSizeMake(imageSize.width * fitScale, imageSize.height * fitScale);
	CGPoint imageOrigin = CGPointMake(
		(screenSize.width - scaledSize.width) / 2.0,
		(screenSize.height - scaledSize.height) / 2.0
	);

	// Convert selected region from screen coords to image pixel coords
	CGRect imageRect = CGRectMake(
		(self.selectedRegion.origin.x - imageOrigin.x) / fitScale * scale,
		(self.selectedRegion.origin.y - imageOrigin.y) / fitScale * scale,
		self.selectedRegion.size.width / fitScale * scale,
		self.selectedRegion.size.height / fitScale * scale
	);

	// Clamp to image bounds
	CGRect imageBounds = CGRectMake(0, 0, imageSize.width * scale, imageSize.height * scale);
	imageRect = CGRectIntersection(imageRect, imageBounds);
	if (CGRectIsEmpty(imageRect)) return nil;

	CGImageRef croppedRef = CGImageCreateWithImageInRect(self.frozenSnapshot.CGImage, imageRect);
	if (!croppedRef) return nil;
	UIImage *cropped = [UIImage imageWithCGImage:croppedRef scale:scale orientation:self.frozenSnapshot.imageOrientation];
	CGImageRelease(croppedRef);
	return cropped;
}

#pragma mark - Toolbar

- (void)buildAndShowToolbar {
	if (!self.frozen || !self.freezeWindow) return;

	LTManager *manager = [LTManager sharedManager];
	NSMutableArray *items = [NSMutableArray array];

	// Close / Unfreeze
	[items addObject:[LTToolbarItem itemWithIdentifier:@"close"
		icon:[UIImage systemImageNamed:@"xmark.circle"]
		hintText:@"Unfreeze"
		action:^{ [self handleCloseAction]; }]];

	// Screenshot
	if ([manager boolForKey:@"ScreenshotEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"screenshot"
			icon:[UIImage systemImageNamed:@"camera.viewfinder"]
			hintText:@"Screenshot"
			action:^{ [self handleScreenshotAction]; }]];
	}

	// Translate (OCR -> Translate)
	if ([manager boolForKey:@"TranslateEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"translate"
			icon:[UIImage systemImageNamed:@"character.bubble"]
			hintText:@"Translate"
			action:^{ [self handleTranslateAction]; }]];
	}

	// AI (OCR -> AI)
	if ([manager boolForKey:@"AIEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"ai"
			icon:[UIImage systemImageNamed:@"sparkles"]
			hintText:@"AI"
			action:^{ [self handleAIAction]; }]];
	}

	// Editor
	if ([manager boolForKey:@"EditorEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"editor"
			icon:[UIImage systemImageNamed:@"slider.horizontal.3"]
			hintText:@"Editor"
			action:^{ [self handleEditorAction]; }]];
	}

	// Long Shot
	if ([manager boolForKey:@"LongShotEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"longshot"
			icon:[UIImage systemImageNamed:@"rectangle.stack"]
			hintText:@"Long Shot"
			action:^{ [self handleLongShotAction]; }]];
	}

	// QR
	[items addObject:[LTToolbarItem itemWithIdentifier:@"qr"
		icon:[UIImage systemImageNamed:@"qrcode"]
		hintText:@"QR Code"
		action:^{ [self handleQRAction]; }]];

	self.toolbar = [[LTToolbarView alloc] init];
	[self.toolbar configureWithItems:items];

	// Anchor toolbar above the selected region
	CGRect anchorRect = self.selectedRegion;
	[self.toolbar presentAnchoredToSelectionRect:anchorRect inWindow:self.freezeWindow];

	// Keep toolbar position updated when region changes
	__weak typeof(self) weakSelf = self;
	self.regionSelectView.regionDidChangeBlock = ^(CGRect region) {
		weakSelf.selectedRegion = region;
		// Reposition toolbar to follow the region's top edge
		if (weakSelf.toolbar) {
			[weakSelf.toolbar presentAnchoredToSelectionRect:region inWindow:weakSelf.freezeWindow];
		}
	};
}

#pragma mark - Toolbar actions (each routes to a real Manager)

- (void)handleCloseAction {
	[self stopFreeze];
}

- (void)handleScreenshotAction {
	UIImage *regionImage = [self imageForSelectedRegion];
	if (!regionImage) {
		NSLog(@"[LinguaTweak] Screenshot: no image for selected region");
		return;
	}
	[[LTScreenshotManager sharedManager] saveImageToPhotos:regionImage completion:^(BOOL success, NSError * _Nullable error) {
		NSLog(@"[LinguaTweak] Screenshot saved: %@ (error: %@)", success ? @"YES" : @"NO", error);
	}];
}

- (void)handleTranslateAction {
	UIImage *regionImage = [self imageForSelectedRegion];
	if (!regionImage) {
		NSLog(@"[LinguaTweak] Translate: no image for selected region");
		return;
	}
	// OCR first, then translate the recognized text
	[[LTOCRManager sharedManager] recognizeTextInImage:regionImage completion:^(NSString * _Nullable text, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error || text.length == 0) {
				LTTranslatePanel *panel = [[LTTranslatePanel alloc] init];
				[panel showLoadingFromRect:self.selectedRegion];
				[panel showError:error ? error.localizedDescription : @"No text recognized"];
				return;
			}
			[[LTTranslateManager sharedManager] translateAndPresent:text fromRect:self.selectedRegion];
		});
	}];
}

- (void)handleAIAction {
	UIImage *regionImage = [self imageForSelectedRegion];
	if (!regionImage) {
		NSLog(@"[LinguaTweak] AI: no image for selected region");
		return;
	}
	[[LTOCRManager sharedManager] recognizeTextInImage:regionImage completion:^(NSString * _Nullable text, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error || text.length == 0) {
				LTTranslatePanel *panel = [[LTTranslatePanel alloc] init];
				[panel showLoadingFromRect:self.selectedRegion];
				[panel showError:error ? error.localizedDescription : @"No text recognized"];
				return;
			}
			[[LTAIManager sharedManager] runAction:LTAIActionSummarize onText:text completion:^(NSString * _Nullable resultText, NSError * _Nullable aiError) {
				dispatch_async(dispatch_get_main_queue(), ^{
					LTTranslatePanel *panel = [[LTTranslatePanel alloc] init];
					if (aiError) {
						[panel showLoadingFromRect:self.selectedRegion];
						[panel showError:aiError.localizedDescription];
					} else {
						[panel showResult:resultText sourceText:text];
					}
				});
			}];
		});
	}];
}

- (void)handleEditorAction {
	UIImage *regionImage = [self imageForSelectedRegion];
	if (!regionImage) {
		NSLog(@"[LinguaTweak] Editor: no image for selected region");
		return;
	}
	[[LTEditorManager sharedManager] beginEditingImage:regionImage];
	NSLog(@"[LinguaTweak] Editor: began editing image of size %@", NSStringFromCGSize(regionImage.size));
	// Note: LTEditorManager currently has no full UI presenter; it holds
	// the base image and operations. A dedicated editor UI is a
	// follow-up phase.
}

- (void)handleLongShotAction {
	// Long screenshot requires a live scroll view, which is not available
	// while the screen is frozen. Inform via log and do nothing destructive.
	NSLog(@"[LinguaTweak] Long Shot: not available while frozen. Unfreeze first, then use the in-app text-selection toolbar.");
}

- (void)handleQRAction {
	UIImage *regionImage = [self imageForSelectedRegion];
	if (!regionImage) {
		NSLog(@"[LinguaTweak] QR: no image for selected region");
		return;
	}
	// Use CoreImage CIDetector for QR detection
	CIImage *ciImage = [[CIImage alloc] initWithCGImage:regionImage.CGImage];
	if (!ciImage) {
		NSLog(@"[LinguaTweak] QR: could not create CIImage");
		return;
	}
	CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode
		context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
	NSArray<CIFeature *> *features = [detector featuresInImage:ciImage];
	if (features.count == 0) {
		NSLog(@"[LinguaTweak] QR: no QR code detected in selected region");
		return;
	}
	for (CIFeature *feature in features) {
		if ([feature isKindOfClass:[CIQRCodeFeature class]]) {
			CIQRCodeFeature *qr = (CIQRCodeFeature *)feature;
			NSLog(@"[LinguaTweak] QR detected: %@", qr.messageString ?: @"(nil)");
		}
	}
}

@end
