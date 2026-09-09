// LTHintLabel.m
#import "LTHintLabel.h"
#import <objc/runtime.h>

static const void *kLTHintTextKey = &kLTHintTextKey;
static const void *kLTHintRecognizerKey = &kLTHintRecognizerKey;

@interface LTHintLabel ()
@property (nonatomic, strong) UILabel *textLabel;
// Fix: private CLASS method called in +handleLongPress: before its definition.
+ (void)showHint:(NSString *)text above:(UIView *)anchorView;
@end

@implementation LTHintLabel

+ (void)attachHintWithText:(NSString *)text toView:(UIView *)view {
	view.userInteractionEnabled = YES;
	objc_setAssociatedObject(view, kLTHintTextKey, text, OBJC_ASSOCIATION_COPY_NONATOMIC);

	UILongPressGestureRecognizer *recognizer =
		[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	recognizer.minimumPressDuration = 2.0; // fixed: 2s to trigger
	objc_setAssociatedObject(view, kLTHintRecognizerKey, recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[view addGestureRecognizer:recognizer];
}

+ (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
	if (recognizer.state != UIGestureRecognizerStateBegan) return;

	UIView *sourceView = recognizer.view;
	NSString *text = objc_getAssociatedObject(sourceView, kLTHintTextKey);
	if (text.length == 0) return;

	[self showHint:text above:sourceView];
}

+ (void)showHint:(NSString *)text above:(UIView *)anchorView {
	UIWindow *window = anchorView.window;
	if (!window) return;

	LTHintLabel *hint = [[LTHintLabel alloc] init];
	hint.translatesAutoresizingMaskIntoConstraints = NO;
	hint.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.85];
	hint.layer.cornerRadius = 6;
	hint.layer.masksToBounds = YES;
	hint.alpha = 0;

	UILabel *label = [[UILabel alloc] init];
	label.text = text;
	label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
	label.textColor = UIColor.whiteColor;
	label.numberOfLines = 1;
	label.translatesAutoresizingMaskIntoConstraints = NO;
	[hint addSubview:label];
	hint.textLabel = label;

	[window addSubview:hint];

	[NSLayoutConstraint activateConstraints:@[
		[label.leadingAnchor constraintEqualToAnchor:hint.leadingAnchor constant:8],
		[label.trailingAnchor constraintEqualToAnchor:hint.trailingAnchor constant:-8],
		[label.topAnchor constraintEqualToAnchor:hint.topAnchor constant:4],
		[label.bottomAnchor constraintEqualToAnchor:hint.bottomAnchor constant:-4],
	]];

	CGRect anchorFrameInWindow = [anchorView convertRect:anchorView.bounds toView:window];
	[hint setNeedsLayout];
	[hint layoutIfNeeded];
	CGSize fitSize = [hint systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

	CGFloat x = CGRectGetMidX(anchorFrameInWindow) - fitSize.width / 2.0;
	CGFloat y = CGRectGetMinY(anchorFrameInWindow) - fitSize.height - 6;

	// Keep on-screen horizontally.
	CGFloat screenWidth = window.bounds.size.width;
	x = MAX(4, MIN(x, screenWidth - fitSize.width - 4));

	hint.frame = CGRectMake(x, y, fitSize.width, fitSize.height);

	[UIView animateWithDuration:0.15 animations:^{
		hint.alpha = 1.0;
	} completion:^(BOOL finished) {
		// Fixed: auto-dismiss after 1 second.
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[UIView animateWithDuration:0.15 animations:^{
				hint.alpha = 0;
			} completion:^(BOOL finished2) {
				[hint removeFromSuperview];
			}];
		});
	}];
}

@end
