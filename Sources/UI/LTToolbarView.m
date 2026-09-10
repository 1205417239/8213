// LTToolbarView.m
#import "LTToolbarView.h"
#import "LTHintLabel.h"

const CGFloat kLTToolbarFixedWidth  = 260.0; // fixed length
const CGFloat kLTToolbarFixedHeight = 44.0;

static const CGFloat kLTToolbarIconSize   = 32.0;
static const CGFloat kLTToolbarIconSpacing = 8.0;
static const CGFloat kLTToolbarScreenMargin = 6.0;

@implementation LTToolbarItem

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                               icon:(UIImage *)icon
                           hintText:(NSString *)hintText
                             action:(void (^)(void))action {
	LTToolbarItem *item = [LTToolbarItem new];
	item.identifier = identifier;
	item.icon = icon;
	item.hintText = hintText;
	item.action = action;
	return item;
}

@end

@interface LTToolbarView ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) NSArray<LTToolbarItem *> *items;
@end

@implementation LTToolbarView

- (instancetype)init {
	self = [super initWithFrame:CGRectMake(0, 0, kLTToolbarFixedWidth, kLTToolbarFixedHeight)];
	if (self) {
		// Transparent, borderless per spec.
		self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.55];
		self.layer.cornerRadius = kLTToolbarFixedHeight / 2.0;
		self.layer.masksToBounds = YES;
		self.layer.borderWidth = 0;

		_scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.backgroundColor = UIColor.clearColor;
		[self addSubview:_scrollView];

		_stackView = [[UIStackView alloc] init];
		_stackView.axis = UILayoutConstraintAxisHorizontal;
		_stackView.alignment = UIStackViewAlignmentCenter;
		_stackView.spacing = kLTToolbarIconSpacing;
		_stackView.translatesAutoresizingMaskIntoConstraints = NO;
		[_scrollView addSubview:_stackView];

		[NSLayoutConstraint activateConstraints:@[
			[_stackView.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor constant:kLTToolbarIconSpacing],
			[_stackView.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor constant:-kLTToolbarIconSpacing],
			[_stackView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
			[_stackView.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor],
			[_stackView.heightAnchor constraintEqualToAnchor:_scrollView.heightAnchor],
		]];
	}
	return self;
}

- (void)configureWithItems:(NSArray<LTToolbarItem *> *)items {
	self.items = items;
	for (UIView *subview in self.stackView.arrangedSubviews) {
		[self.stackView removeArrangedSubview:subview];
		[subview removeFromSuperview];
	}

	for (LTToolbarItem *item in items) {
		UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
		button.tintColor = UIColor.whiteColor;
		[button setImage:[item.icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
		button.frame = CGRectMake(0, 0, kLTToolbarIconSize, kLTToolbarIconSize);
		[button.widthAnchor constraintEqualToConstant:kLTToolbarIconSize].active = YES;
		[button.heightAnchor constraintEqualToConstant:kLTToolbarIconSize].active = YES;
		[button addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
			if (item.action) item.action();
		}] forControlEvents:UIControlEventTouchUpInside];

		if (item.hintText.length > 0) {
			[LTHintLabel attachHintWithText:item.hintText toView:button];
		}

		[self.stackView addArrangedSubview:button];
	}
}

#pragma mark - Presentation / edge avoidance

- (void)presentAnchoredToSelectionRect:(CGRect)selectionRect inWindow:(UIWindow *)window {
	CGFloat screenWidth = window.bounds.size.width;

	CGFloat proposedX = CGRectGetMinX(selectionRect); // default: left-align to selection
	CGFloat y = CGRectGetMinY(selectionRect) - kLTToolbarFixedHeight - 8;
	if (y < kLTToolbarScreenMargin) {
		// Not enough room above; place below the selection instead.
		y = CGRectGetMaxY(selectionRect) + 8;
	}

	if (proposedX + kLTToolbarFixedWidth > screenWidth - kLTToolbarScreenMargin) {
		// Overflow on the right: align toolbar's right edge to selection's right edge.
		proposedX = CGRectGetMaxX(selectionRect) - kLTToolbarFixedWidth;
	}
	// Clamp to screen bounds as a final safety net.
	proposedX = MAX(kLTToolbarScreenMargin, MIN(proposedX, screenWidth - kLTToolbarFixedWidth - kLTToolbarScreenMargin));

	self.frame = CGRectMake(proposedX, y, kLTToolbarFixedWidth, kLTToolbarFixedHeight);
	self.alpha = 0;
	if (!self.superview) {
		[window addSubview:self];
	}

	[self.scrollView layoutIfNeeded];
	self.scrollView.contentSize = CGSizeMake(self.stackView.frame.size.width + kLTToolbarIconSpacing * 2, kLTToolbarFixedHeight);

	[UIView animateWithDuration:0.18 animations:^{
		self.alpha = 1.0;
	}];
}

- (void)dismiss {
	[UIView animateWithDuration:0.15 animations:^{
		self.alpha = 0;
	} completion:^(BOOL finished) {
		[self removeFromSuperview];
	}];
}

@end
