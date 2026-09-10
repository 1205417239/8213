#import <UIKit/UIKit.h>
#import "LTManager.h"
#import "LTFreezeManager.h"
#import "LTScreenshotManager.h"
#import "LTTranslateManager.h"
#import "LTAIManager.h"
#import "LTEditorManager.h"
#import "LTLongShotManager.h"
#import "LTSileoTranslateManager.h"
#import "LTToolbarView.h"

#pragma mark - Window

static UIWindow *LTActiveWindow(void) {
for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
if (scene.activationState != UISceneActivationStateForegroundActive) {
continue;
}
if (![scene isKindOfClass:[UIWindowScene class]]) {
continue;
}
for (UIWindow *window in ((UIWindowScene *)scene).windows) {
if (window.isKeyWindow) {
return window;
}
}
}
return UIApplication.sharedApplication.keyWindow;
}

#pragma mark - Selected Text

static NSString *LTSelectedText(UIView *view) {
UIResponder *responder = view;
while (responder) {
if ([responder conformsToProtocol:@protocol(UITextInput)]) {
id<UITextInput> input = (id<UITextInput>)responder;
UITextRange *range = input.selectedTextRange;
if (range && !range.isEmpty) {
NSString *text = [input textInRange:range];
if (text.length > 0) {
return text;
}
}
}
responder = responder.nextResponder;
}
return nil;
}

#pragma mark - Scroll View

static UIScrollView *LTNearestScrollView(UIView *view) {
UIView *current = view;
while (current) {
if ([current isKindOfClass:[UIScrollView class]]) {
return (UIScrollView *)current;
}
current = current.superview;
}
return nil;
}

#pragma mark - Toolbar (kept alive while presented)

static LTToolbarView *LTCurrentToolbar = nil;

static void LTShowToolbar(CGRect selectionRect, UIView *sourceView) {
LTManager *manager = [LTManager sharedManager];
if (![manager isTweakEnabled]) {
return;
}

NSMutableArray *items = [NSMutableArray array];

/*
* Translate
*/
if ([manager boolForKey:@"TranslateEnabled" default:YES]) {
[items addObject:
[LTToolbarItem itemWithIdentifier:@"translate"
icon:[UIImage systemImageNamed:@"character.bubble"]
hintText:@"Translate"
action:^{
NSString *text = LTSelectedText(sourceView);
if (text.length > 0) {
[[LTTranslateManager sharedManager]
translateAndPresent:text
fromRect:selectionRect];
}
}]];
}

/*
* AI
*/
if ([manager boolForKey:@"AIEnabled" default:NO]) {
[items addObject:
[LTToolbarItem itemWithIdentifier:@"ai"
icon:[UIImage systemImageNamed:@"sparkles"]
hintText:@"AI"
action:^{
NSString *text = LTSelectedText(sourceView);
if (text.length > 0) {
[[LTAIManager sharedManager]
runAction:LTAIActionSummarize
onText:text
completion:^(NSString * _Nullable resultText, NSError * _Nullable error) {
if (resultText.length > 0) {
dispatch_async(dispatch_get_main_queue(), ^{
[[LTTranslateManager sharedManager]
translateAndPresent:resultText
fromRect:selectionRect];
});
}
}];
}
}]];
}

/*
* Freeze
*/
if ([manager boolForKey:@"FreezeEnabled" default:YES]) {
[items addObject:
[LTToolbarItem itemWithIdentifier:@"freeze"
icon:[UIImage systemImageNamed:@"pause.circle"]
hintText:@"Freeze"
action:^{
[[LTFreezeManager sharedManager] toggleFreeze];
}]];
}

/*
* Screenshot
*/
if ([manager boolForKey:@"ScreenshotEnabled" default:YES]) {
[items addObject:
[LTToolbarItem itemWithIdentifier:@"screenshot"
icon:[UIImage systemImageNamed:@"camera.viewfinder"]
hintText:@"Screenshot"
action:^{
[[LTScreenshotManager sharedManager]
captureRegion:selectionRect
completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
if (image) {
[[LTScreenshotManager sharedManager]
saveImageToPhotos:image
completion:nil];
}
}];
}]];
}

/*
* Editor
*/
if ([manager boolForKey:@"EditorEnabled" default:YES]) {
[items addObject:
[LTToolbarItem itemWithIdentifier:@"editor"
icon:[UIImage systemImageNamed:@"slider.horizontal.3"]
hintText:@"Editor"
action:^{
[[LTScreenshotManager sharedManager]
captureRegion:selectionRect
completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
if (image) {
dispatch_async(dispatch_get_main_queue(), ^{
[[LTEditorManager sharedManager] beginEditingImage:image];
});
}
}];
}]];
}

/*
* Long Screenshot
*/
if ([manager boolForKey:@"LongShotEnabled" default:YES]) {
[items addObject:
[LTToolbarItem itemWithIdentifier:@"longshot"
icon:[UIImage systemImageNamed:@"rectangle.stack"]
hintText:@"Long Screenshot"
action:^{
UIScrollView *scrollView = LTNearestScrollView(sourceView);
if (!scrollView) {
return;
}

LTLongShotManager *longShot = [LTLongShotManager sharedManager];
[longShot beginSessionWithScrollView:scrollView];
[longShot captureNextFrameWithProgress:nil];

dispatch_after(
dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
dispatch_get_main_queue(),
^{
[longShot finishSessionWithCompletion:^(UIImage * _Nullable stitchedImage, NSError * _Nullable error) {
if (stitchedImage) {
[[LTScreenshotManager sharedManager]
saveImageToPhotos:stitchedImage
completion:nil];
}
}];
});
}]];
}

/*
* No functions enabled
*/
if (items.count == 0) {
return;
}

UIWindow *window = sourceView.window;
if (!window) {
window = LTActiveWindow();
}
if (!window) {
return;
}

dispatch_async(dispatch_get_main_queue(), ^{
LTToolbarView *toolbar = [[LTToolbarView alloc] init];
[toolbar configureWithItems:items];
[toolbar presentAnchoredToSelectionRect:selectionRect inWindow:window];
LTCurrentToolbar = toolbar;
});
}

#pragma mark - UIMenuController

%hook UIMenuController

- (void)setTargetRect:(CGRect)targetRect inView:(UIView *)targetView {
%orig;

if (![[LTManager sharedManager] isTweakEnabled]) {
return;
}
if (!targetView.window) {
return;
}

CGRect rectInWindow = [targetView convertRect:targetRect toView:nil];
dispatch_async(dispatch_get_main_queue(), ^{
LTShowToolbar(rectInWindow, targetView);
});
}

%end

#pragma mark - UITextView

%hook UITextView

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange {
%orig;

if (!selectedTextRange || selectedTextRange.isEmpty) {
return;
}
if (![[LTManager sharedManager] isTweakEnabled]) {
return;
}

dispatch_async(dispatch_get_main_queue(), ^{
if (!self.window) {
return;
}
CGRect rect = [self firstRectForRange:selectedTextRange];
if (CGRectIsEmpty(rect)) {
return;
}
CGRect rectInWindow = [self convertRect:rect toView:nil];
LTShowToolbar(rectInWindow, self);
});
}

%end

#pragma mark - UITextField

%hook UITextField

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange {
%orig;

if (!selectedTextRange || selectedTextRange.isEmpty) {
return;
}
if (![[LTManager sharedManager] isTweakEnabled]) {
return;
}

dispatch_async(dispatch_get_main_queue(), ^{
if (!self.window) {
return;
}
CGRect rect = [self convertRect:self.bounds toView:nil];
LTShowToolbar(rect, self);
});
}

%end

#pragma mark - Sileo

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
%orig;

if (![[LTManager sharedManager] boolForKey:@"SileoTranslateEnabled" default:NO]) {
return;
}

NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
if ([bundleID.lowercaseString containsString:@"sileo"]) {
[[LTSileoTranslateManager sharedManager] translateLabelsInView:self.view];
}
}

%end

#pragma mark - Constructor

%ctor {
LTManager *manager = [LTManager sharedManager];
[manager registerModule:[LTFreezeManager sharedManager]];
[manager registerModule:[LTScreenshotManager sharedManager]];
[manager registerModule:[LTTranslateManager sharedManager]];
[manager registerModule:[LTAIManager sharedManager]];
[manager registerModule:[LTEditorManager sharedManager]];
[manager registerModule:[LTLongShotManager sharedManager]];
[manager registerModule:[LTSileoTranslateManager sharedManager]];
[manager activateAllModules];
}
