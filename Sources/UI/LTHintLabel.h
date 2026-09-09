// LTHintLabel.h
// Small tooltip shown above a toolbar icon after a 2-second long press,
// auto-dismissing after 1 second. English-only text (no localized
// Chinese strings per product requirement — captions are passed in by
// the caller, plain ASCII English expected).

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTHintLabel : UIView

// Attaches a long-press recognizer (minimumPressDuration = 2.0) to
// `view` that shows `text` above it, then auto-dismisses after 1s.
+ (void)attachHintWithText:(NSString *)text toView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
