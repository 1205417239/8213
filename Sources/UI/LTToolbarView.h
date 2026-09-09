// LTToolbarView.h
// Floating icon toolbar shown above a text selection. Requirements
// implemented here:
//  - transparent, borderless background
//  - fixed overall length (kLTToolbarFixedWidth / Height)
//  - icons scroll horizontally if they exceed the fixed width
//  - default left-aligned to the selection rect
//  - if that would overflow the right edge of the screen, the toolbar's
//    right edge is instead aligned to the selection rect's right edge
//  - long-press an icon (2s) shows an English-only hint (LTHintLabel),
//    auto-dismissing after 1s (no extra wiring needed by callers)
//
// Extension point: LTToolbarItem is a plain struct-like model; add new
// items by appending to the array passed to -configureWithItems: — no
// other UI code needs to change.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat kLTToolbarFixedWidth;
extern const CGFloat kLTToolbarFixedHeight;

@interface LTToolbarItem : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic, copy) NSString *hintText;   // English only
@property (nonatomic, copy) void (^action)(void);
+ (instancetype)itemWithIdentifier:(NSString *)identifier
                               icon:(UIImage *)icon
                           hintText:(NSString *)hintText
                             action:(void (^)(void))action;
@end

@interface LTToolbarView : UIView

// Builds/replaces the icon row.
- (void)configureWithItems:(NSArray<LTToolbarItem *> *)items;

// Presents the toolbar anchored to `selectionRect` (screen coords),
// applying left-align-by-default / right-edge-avoidance as described
// above. Call on the main thread.
- (void)presentAnchoredToSelectionRect:(CGRect)selectionRect inWindow:(UIWindow *)window;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
