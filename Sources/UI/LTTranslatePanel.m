// LTTranslatePanel.m
#import "LTTranslatePanel.h"

const CGFloat kLTPanelHeightFraction = 1.0 / 3.0;
const CGFloat kLTPanelCornerRadius   = 24.0; // half-circle look on the two top corners

@interface LTTranslatePanel () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIWindow *panelWindow;
@property (nonatomic, strong) UIView *dimmingView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *grabberView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) CGFloat containerHeight;
@end

@implementation LTTranslatePanel

- (void)ensureWindowPresented {
	if (self.panelWindow) return;

	UIWindowScene *scene = nil;
	for (UIWindowScene *s in UIApplication.sharedApplication.connectedScenes) {
		if (s.activationState == UISceneActivationStateForegroundActive) { scene = s; break; }
	}
	if (!scene) return;

	CGRect screenBounds = scene.coordinateSpace.bounds;
	self.containerHeight = CGRectGetHeight(screenBounds) * kLTPanelHeightFraction;

	self.panelWindow = [[UIWindow alloc] initWithWindowScene:scene];
	self.panelWindow.windowLevel = UIWindowLevelAlert;
	self.panelWindow.backgroundColor = UIColor.clearColor;
	self.panelWindow.frame = screenBounds;

	UIViewController *rootVC = [[UIViewController alloc] init];
	rootVC.view.backgroundColor = UIColor.clearColor;
	self.panelWindow.rootViewController = rootVC;

	// Dimming background — tapping it (blank area) dismisses the panel.
	self.dimmingView = [[UIView alloc] initWithFrame:screenBounds];
	self.dimmingView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.0];
	[rootVC.view addSubview:self.dimmingView];

	UITapGestureRecognizer *tap =
		[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)];
	tap.delegate = self;
	[self.dimmingView addGestureRecognizer:tap];

	// Container: fixed height, bottom third, rounded top corners only.
	self.containerView = [[UIView alloc] initWithFrame:
		CGRectMake(0, CGRectGetHeight(screenBounds), CGRectGetWidth(screenBounds), self.containerHeight)];
	self.containerView.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.98];
	self.containerView.layer.cornerRadius = kLTPanelCornerRadius;
	self.containerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner; // top-left + top-right only
	self.containerView.layer.masksToBounds = YES;
	[rootVC.view addSubview:self.containerView];

	// Grabber (visual affordance for swipe-down-to-close).
	self.grabberView = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(screenBounds) - 36) / 2.0, 8, 36, 5)];
	self.grabberView.backgroundColor = [UIColor.labelColor colorWithAlphaComponent:0.25];
	self.grabberView.layer.cornerRadius = 2.5;
	[self.containerView addSubview:self.grabberView];

	self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
	self.spinner.center = CGPointMake(CGRectGetWidth(self.containerView.bounds) / 2.0, self.containerHeight / 2.0);
	self.spinner.hidesWhenStopped = YES;
	[self.containerView addSubview:self.spinner];

	self.textView = [[UITextView alloc] initWithFrame:
		CGRectMake(16, 24, CGRectGetWidth(screenBounds) - 32, self.containerHeight - 40)];
	self.textView.backgroundColor = UIColor.clearColor;
	self.textView.font = [UIFont systemFontOfSize:16];
	self.textView.editable = NO;
	self.textView.alwaysBounceVertical = YES; // scrollable content
	self.textView.showsVerticalScrollIndicator = YES;
	self.textView.hidden = YES;
	[self.containerView addSubview:self.textView];

	// Swipe down to dismiss.
	UIPanGestureRecognizer *pan =
		[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	pan.delegate = self;
	[self.containerView addGestureRecognizer:pan];

	self.panelWindow.hidden = NO;
}

- (void)animateIn {
	UIWindowScene *scene = self.panelWindow.windowScene;
	CGRect screenBounds = scene.coordinateSpace.bounds;
	CGFloat targetY = CGRectGetHeight(screenBounds) - self.containerHeight;

	[UIView animateWithDuration:0.28 delay:0
		usingSpringWithDamping:0.9 initialSpringVelocity:0.4 options:0
		animations:^{
			self.dimmingView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
			CGRect f = self.containerView.frame;
			f.origin.y = targetY;
			self.containerView.frame = f;
		} completion:nil];
}

#pragma mark - Public

- (void)showLoadingFromRect:(CGRect)anchorRect {
	[self ensureWindowPresented];
	self.textView.hidden = YES;
	[self.spinner startAnimating];
	[self animateIn];
}

- (void)showResult:(nullable NSString *)translatedText sourceText:(NSString *)sourceText {
	[self ensureWindowPresented];
	[self.spinner stopAnimating];
	self.textView.hidden = NO;

	NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] init];
	[attributed appendAttributedString:[[NSAttributedString alloc] initWithString:
		(translatedText ?: @"") attributes:@{
			NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold],
			NSForegroundColorAttributeName: UIColor.labelColor,
		}]];
	[attributed appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
	[attributed appendAttributedString:[[NSAttributedString alloc] initWithString:sourceText attributes:@{
		NSFontAttributeName: [UIFont systemFontOfSize:14],
		NSForegroundColorAttributeName: UIColor.secondaryLabelColor,
	}]];
	self.textView.attributedText = attributed;

	[self animateIn];
}

- (void)showError:(NSString *)message {
	[self ensureWindowPresented];
	[self.spinner stopAnimating];
	self.textView.hidden = NO;
	self.textView.text = message;
	self.textView.textColor = UIColor.systemRedColor;
	[self animateIn];
}

- (void)dismiss {
	if (!self.panelWindow) return;
	UIWindowScene *scene = self.panelWindow.windowScene;
	CGRect screenBounds = scene.coordinateSpace.bounds;

	[UIView animateWithDuration:0.22 animations:^{
		self.dimmingView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.0];
		CGRect f = self.containerView.frame;
		f.origin.y = CGRectGetHeight(screenBounds);
		self.containerView.frame = f;
	} completion:^(BOOL finished) {
		self.panelWindow.hidden = YES;
		self.panelWindow = nil;
	}];
}

#pragma mark - Gestures

- (void)handleBackgroundTap:(UITapGestureRecognizer *)recognizer {
	CGPoint location = [recognizer locationInView:self.dimmingView];
	if (!CGRectContainsPoint(self.containerView.frame, location)) {
		[self dismiss]; // tapping blank area closes the panel
	}
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:self.containerView];
	UIWindowScene *scene = self.panelWindow.windowScene;
	CGRect screenBounds = scene.coordinateSpace.bounds;
	CGFloat restingY = CGRectGetHeight(screenBounds) - self.containerHeight;

	switch (recognizer.state) {
		case UIGestureRecognizerStateChanged: {
			CGFloat newY = MAX(restingY, restingY + translation.y);
			CGRect f = self.containerView.frame;
			f.origin.y = newY;
			self.containerView.frame = f;
			break;
		}
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled: {
			CGFloat velocityY = [recognizer velocityInView:self.containerView].y;
			if (translation.y > self.containerHeight * 0.25 || velocityY > 800) {
				[self dismiss]; // swipe down to close
			} else {
				[self animateIn]; // snap back
			}
			break;
		}
		default:
			break;
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return NO;
}

@end
