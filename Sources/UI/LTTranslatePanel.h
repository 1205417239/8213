// LTTranslatePanel.h
// Translation result window. Requirements implemented here:
//  - occupies the bottom third of the screen
//  - fixed size (kLTPanelHeightFraction of screen height)
//  - scrollable content (UITextView)
//  - swipe down to dismiss
//  - tap on the dimming background (blank area) to dismiss
//  - top-left and top-right corners are half-circle rounded
//    (radius == half the corner-side length, i.e. a true semicircle
//    cut using the panel's own height-independent corner radius)
//
// Extension point: -showResult:sourceText: is the only content entry
// point; add richer content (e.g. multiple engine results in tabs) by
// extending the content stack view without touching presentation code.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat kLTPanelHeightFraction; // 1/3 of screen height
extern const CGFloat kLTPanelCornerRadius;

@interface LTTranslatePanel : NSObject

// Shows the panel anchored near `anchorRect` in a loading state.
- (void)showLoadingFromRect:(CGRect)anchorRect;

// Fills in the translated result (source text shown for reference).
- (void)showResult:(nullable NSString *)translatedText sourceText:(NSString *)sourceText;

- (void)showError:(NSString *)message;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
