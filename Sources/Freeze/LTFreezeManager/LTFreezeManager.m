// LTFreezeManager.m
#import "LTFreezeManager.h"

@interface LTFreezeManager ()
@property (nonatomic, strong) UIWindow *freezeWindow;
@property (nonatomic, strong) UIImageView *freezeImageView;
@property (nonatomic, assign) BOOL frozen;
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
	// No persistent hooks required at rest; freeze is invoked on-demand
	// via toolbar action or a future gesture recognizer registration
	// point (see Tweak.x for the long-press trigger hook-up).
}

- (void)deactivate {
	[self unfreeze];
}

#pragma mark - Public

- (UIImage *)snapshotOfKeyWindow {
	UIWindow *keyWindow = nil;
	for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (scene.activationState == UISceneActivationStateForegroundActive) {
			for (UIWindow *w in scene.windows) {
				if (w.isKeyWindow) { keyWindow = w; break; }
			}
		}
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

- (void)freezeCurrentScreen {
	if (self.frozen) return;

	UIImage *snapshot = [self snapshotOfKeyWindow];
	if (!snapshot) return;

	UIWindowScene *scene = nil;
	for (UIWindowScene *s in UIApplication.sharedApplication.connectedScenes) {
		if (s.activationState == UISceneActivationStateForegroundActive) { scene = s; break; }
	}
	if (!scene) return;

	self.freezeWindow = [[UIWindow alloc] initWithWindowScene:scene];
	self.freezeWindow.windowLevel = UIWindowLevelStatusBar + 1;
	self.freezeWindow.backgroundColor = UIColor.blackColor;

	self.freezeImageView = [[UIImageView alloc] initWithFrame:self.freezeWindow.bounds];
	self.freezeImageView.image = snapshot;
	self.freezeImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.freezeImageView.userInteractionEnabled = YES;
	[self.freezeWindow addSubview:self.freezeImageView];

	// Extension point: attach UILongPressGestureRecognizer / text
	// selection UI to freezeImageView here for OCR-driven selection.

	UITapGestureRecognizer *doubleTap =
		[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unfreeze)];
	doubleTap.numberOfTapsRequired = 2;
	[self.freezeImageView addGestureRecognizer:doubleTap];

	self.freezeWindow.hidden = NO;
	self.frozen = YES;
}

- (void)unfreeze {
	if (!self.frozen) return;
	[UIView animateWithDuration:0.2 animations:^{
		self.freezeWindow.alpha = 0;
	} completion:^(BOOL finished) {
		self.freezeWindow.hidden = YES;
		self.freezeWindow = nil;
		self.freezeImageView = nil;
	}];
	self.frozen = NO;
}

- (void)toggleFreeze {
	if (self.frozen) {
		[self unfreeze];
	} else {
		[self freezeCurrentScreen];
	}
}

@end
