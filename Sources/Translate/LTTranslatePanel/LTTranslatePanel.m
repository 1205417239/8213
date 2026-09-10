#import "LTTranslatePanel.h"

@interface LTTranslatePanel ()
@property (nonatomic, strong) UIWindow *panelWindow;
@property (nonatomic, strong) UITextView *sourceTextView;
@property (nonatomic, strong) UITextView *translatedTextView;
@end

@implementation LTTranslatePanel

+ (instancetype)sharedPanel {
    static LTTranslatePanel *panel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        panel = [[LTTranslatePanel alloc] init];
    });
    return panel;
}

- (void)showSource:(NSString *)source
        translated:(NSString *)translated
         fromRect:(CGRect)rect {

    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismiss];

        UIWindowScene *scene = nil;
        for (UIWindowScene *s in UIApplication.sharedApplication.connectedScenes) {
            if (s.activationState == UISceneActivationStateForegroundActive) {
                scene = s;
                break;
            }
        }

        if (!scene) return;

        self.panelWindow =
            [[UIWindow alloc] initWithWindowScene:scene];

        self.panelWindow.frame = scene.coordinateSpace.bounds;
        self.panelWindow.windowLevel = UIWindowLevelAlert + 20;
        self.panelWindow.backgroundColor = UIColor.clearColor;

        UIBlurEffect *blur =
            [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];

        UIVisualEffectView *card =
            [[UIVisualEffectView alloc] initWithEffect:blur];

        CGFloat width = MIN(380.0,
                            CGRectGetWidth(self.panelWindow.bounds) - 24.0);

        CGFloat height = 300.0;

        card.frame = CGRectMake(
            (CGRectGetWidth(self.panelWindow.bounds) - width) / 2.0,
            CGRectGetHeight(self.panelWindow.bounds) - height - 70.0,
            width,
            height
        );

        card.layer.cornerRadius = 22.0;
        card.clipsToBounds = YES;

        [self.panelWindow addSubview:card];

        UILabel *title =
            [[UILabel alloc]
             initWithFrame:CGRectMake(18, 12, width - 70, 28)];

        title.text = @"翻译";
        title.font =
            [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];

        [card.contentView addSubview:title];

        UIButton *close =
            [UIButton buttonWithType:UIButtonTypeSystem];

        close.frame = CGRectMake(width - 48, 10, 34, 34);
        [close setImage:[UIImage systemImageNamed:@"xmark"]
              forState:UIControlStateNormal];

        [close addTarget:self
                  action:@selector(dismiss)
        forControlEvents:UIControlEventTouchUpInside];

        [card.contentView addSubview:close];

        UILabel *sourceLabel =
            [[UILabel alloc]
             initWithFrame:CGRectMake(18, 48, width - 36, 20)];

        sourceLabel.text = @"原文";
        sourceLabel.font =
            [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];

        sourceLabel.textColor =
            [UIColor secondaryLabelColor];

        [card.contentView addSubview:sourceLabel];

        self.sourceTextView =
            [[UITextView alloc]
             initWithFrame:CGRectMake(14, 68, width - 28, 72)];

        self.sourceTextView.text = source ?: @"";
        self.sourceTextView.editable = NO;
        self.sourceTextView.selectable = YES;
        self.sourceTextView.backgroundColor = UIColor.clearColor;
        self.sourceTextView.font =
            [UIFont systemFontOfSize:15];

        [card.contentView addSubview:self.sourceTextView];

        UIButton *copySource =
            [UIButton buttonWithType:UIButtonTypeSystem];

        copySource.frame =
            CGRectMake(width - 50, 105, 36, 36);

        [copySource setImage:
            [UIImage systemImageNamed:@"doc.on.doc"]
            forState:UIControlStateNormal];

        [copySource addTarget:self
                       action:@selector(copySource)
             forControlEvents:UIControlEventTouchUpInside];

        [card.contentView addSubview:copySource];

        UILabel *translatedLabel =
            [[UILabel alloc]
             initWithFrame:CGRectMake(18, 145, width - 36, 20)];

        translatedLabel.text = @"译文";
        translatedLabel.font =
            [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];

        translatedLabel.textColor =
            [UIColor secondaryLabelColor];

        [card.contentView addSubview:translatedLabel];

        self.translatedTextView =
            [[UITextView alloc]
             initWithFrame:CGRectMake(14, 165, width - 28, 88)];

        self.translatedTextView.text =
            translated ?: @"";

        self.translatedTextView.editable = NO;
        self.translatedTextView.selectable = YES;
        self.translatedTextView.backgroundColor =
            UIColor.clearColor;

        self.translatedTextView.font =
            [UIFont systemFontOfSize:16];

        [card.contentView addSubview:self.translatedTextView];

        UIButton *copyTranslated =
            [UIButton buttonWithType:UIButtonTypeSystem];

        copyTranslated.frame =
            CGRectMake(width - 50, 215, 36, 36);

        [copyTranslated setImage:
            [UIImage systemImageNamed:@"doc.on.doc"]
            forState:UIControlStateNormal];

        [copyTranslated addTarget:self
                           action:@selector(copyTranslated)
                 forControlEvents:UIControlEventTouchUpInside];

        [card.contentView addSubview:copyTranslated];

        self.panelWindow.hidden = NO;
    });
}

- (void)copySource {
    UIPasteboard.generalPasteboard.string =
        self.sourceTextView.text ?: @"";
}

- (void)copyTranslated {
    UIPasteboard.generalPasteboard.string =
        self.translatedTextView.text ?: @"";
}

- (void)dismiss {
    self.panelWindow.hidden = YES;
    self.panelWindow = nil;
    self.sourceTextView = nil;
    self.translatedTextView = nil;
}

@end
