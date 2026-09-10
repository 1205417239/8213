#import "LTSileoTranslateManager.h"

@implementation LTSileoTranslateManager

+ (instancetype)sharedManager {
    static LTSileoTranslateManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)activate {
    self.enabled = [[LTManager sharedManager]
                    boolForKey:@"SileoTranslateEnabled"
                    default:YES];
}

- (void)deactivate {
    self.enabled = NO;
}

- (void)reloadPreferences {
    self.enabled = [[LTManager sharedManager]
                    boolForKey:@"SileoTranslateEnabled"
                    default:YES];
}

- (void)translateView:(UIView *)view {
    if (!self.enabled || !view) {
        return;
    }

    NSMutableString *text = [NSMutableString string];
    [self collectTextFromView:view into:text];

    if (text.length == 0) {
        return;
    }

    [[LTTranslateManager sharedManager]
     translateText:text
     targetLanguage:@"zh-CN"
     completion:^(NSString *translatedText, NSError *error) {
        if (error || translatedText.length == 0) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyTranslation:translatedText toView:view];
        });
    }];
}

#pragma mark - Collect

- (void)collectTextFromView:(UIView *)view
                       into:(NSMutableString *)result {

    if ([view isKindOfClass:[UILabel class]]) {
        NSString *text = ((UILabel *)view).text;
        if (text.length) {
            [result appendString:text];
            [result appendString:@"\n"];
        }
    }
    else if ([view isKindOfClass:[UITextView class]]) {
        NSString *text = ((UITextView *)view).text;
        if (text.length) {
            [result appendString:text];
            [result appendString:@"\n"];
        }
    }

    for (UIView *subview in view.subviews) {
        [self collectTextFromView:subview into:result];
    }
}

#pragma mark - Apply

- (void)applyTranslation:(NSString *)translatedText
                  toView:(UIView *)view {

    NSArray<NSString *> *lines =
        [translatedText componentsSeparatedByString:@"\n"];

    __block NSUInteger index = 0;

    [self applyLines:lines toView:view index:&index];
}

- (void)applyLines:(NSArray<NSString *> *)lines
            toView:(UIView *)view
             index:(NSUInteger *)index {

    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;

        if (*index < lines.count) {
            NSString *line = lines[*index];
            if (line.length) {
                label.text = line;
            }
            (*index)++;
        }
    }
    else if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;

        if (*index < lines.count) {
            textView.text = lines[*index];
            (*index)++;
        }
    }

    for (UIView *subview in view.subviews) {
        [self applyLines:lines
                  toView:subview
                   index:index];
    }
}

@end
