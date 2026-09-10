#import "LTToolbarView.h"

@implementation LTToolbarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor =
            [UIColor colorWithWhite:0.08 alpha:0.88];
        self.layer.cornerRadius = 22.0;
        self.layer.masksToBounds = YES;

        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.alwaysBounceHorizontal = YES;
        [self addSubview:_scrollView];

        _stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.spacing = 6.0;
        [_scrollView addSubview:_stackView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat h = self.bounds.size.height;

    self.scrollView.frame =
        CGRectMake(8.0, 0.0,
                   self.bounds.size.width - 16.0,
                   h);

    CGSize size =
        [self.stackView systemLayoutSizeFittingSize:
            CGSizeMake(CGFLOAT_MAX, h)];

    self.stackView.frame =
        CGRectMake(0.0, 0.0,
                   MAX(size.width, self.scrollView.bounds.size.width),
                   h);

    self.scrollView.contentSize = self.stackView.bounds.size;
}

#pragma mark - Buttons

- (UIButton *)buttonWithSymbol:(NSString *)symbol
                          title:(NSString *)title {

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration
            configurationWithPointSize:19.0
                                weight:UIImageSymbolWeightMedium];

    UIImage *image =
        [UIImage systemImageNamed:symbol
             withConfiguration:config];

    [button setImage:image forState:UIControlStateNormal];
    button.tintColor = UIColor.whiteColor;

    button.accessibilityLabel = title;
    button.frame = CGRectMake(0, 0, 40, 40);

    return button;
}

- (void)addButtonWithSymbol:(NSString *)symbol
                      title:(NSString *)title
                      target:(id)target
                      action:(SEL)action {

    UIButton *button =
        [self buttonWithSymbol:symbol title:title];

    [button addTarget:target
               action:action
     forControlEvents:UIControlEventTouchUpInside];

    [self.stackView addArrangedSubview:button];
}

#pragma mark - Selection

- (void)showAtRect:(CGRect)rect
           inView:(UIView *)view {

    if (!view) {
        return;
    }

    if (self.superview != view) {
        [self removeFromSuperview];
        [view addSubview:self];
    }

    CGFloat width = MIN(280.0,
                        view.bounds.size.width - 20.0);

    CGFloat x =
        MAX(10.0,
            MIN(CGRectGetMidX(rect) - width / 2.0,
                view.bounds.size.width - width - 10.0));

    CGFloat y = CGRectGetMinY(rect) - 54.0;

    if (y < 10.0) {
        y = CGRectGetMaxY(rect) + 10.0;
    }

    if (y + 44.0 > view.bounds.size.height - 10.0) {
        y = view.bounds.size.height - 54.0;
    }

    self.frame = CGRectMake(x, y, width, 44.0);
}

- (void)dismiss {
    [self removeFromSuperview];
}

@end
