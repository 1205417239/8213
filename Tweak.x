// Tweak.x
// LinguaTweak entry point. Registers all feature modules with
// LTManager, and hooks UIMenuController's edit-menu (the system
// text-selection callout) as the trigger point for showing our
// floating toolbar next to the current text selection.
//
// Extension point: add new %hook blocks per-host-app (e.g. Sileo) by
// checking the running bundle identifier once at %ctor time and
// conditionally installing extra hooks below the base hook set.

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

static LTToolbarView *gToolbar = nil;

static UIImage *LTIcon(NSString *systemName) {
	UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
	return [UIImage systemImageNamed:systemName withConfiguration:config] ?: [UIImage systemImageNamed:@"questionmark.circle"];
}

static NSString *LTCurrentSelectedText(void) {
	// Extension point: resolve real selected text from the first
	// responder (UITextInput protocol) once wired to a concrete text
	// view/field; placeholder keeps the pipeline testable end-to-end.
	UIResponder *firstResponder = nil;
	UIWindow *keyWindow = nil;
	for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (scene.activationState == UISceneActivationStateForegroundActive) {
			for (UIWindow *w in scene.windows) {
				if (w.isKeyWindow) { keyWindow = w; break; }
			}
		}
	}
	if (!keyWindow) return @"";
	firstResponder = [keyWindow valueForKey:@"firstResponder"]; // best-effort probe
	if ([firstResponder conformsToProtocol:@protocol(UITextInput)]) {
		UITextRange *selectedRange = ((id<UITextInput>)firstResponder).selectedTextRange;
		if (selectedRange) {
			return [(id<UITextInput>)firstResponder textInRange:selectedRange] ?: @"";
		}
	}
	return @"";
}

static void LTShowToolbarForSelection(CGRect selectionRectInWindow, UIWindow *window) {
	if (![[LTManager sharedManager] boolForKey:@"ToolbarEnabled" default:YES]) return;

	if (!gToolbar) {
		gToolbar = [[LTToolbarView alloc] init];
	}

	__weak UIWindow *weakWindow = window;
	NSMutableArray<LTToolbarItem *> *items = [NSMutableArray array];

	if ([[LTManager sharedManager] boolForKey:@"TranslateEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"translate" icon:LTIcon(@"character.bubble")
			hintText:@"Translate" action:^{
				NSString *text = LTCurrentSelectedText();
				[[LTTranslateManager sharedManager] translateAndPresent:text fromRect:selectionRectInWindow];
			}]];
	}
	if ([[LTManager sharedManager] boolForKey:@"AIEnabled" default:NO]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"ai" icon:LTIcon(@"sparkles")
			hintText:@"AI Assist" action:^{
				NSString *text = LTCurrentSelectedText();
				[[LTAIManager sharedManager] runAction:LTAIActionSummarize onText:text completion:^(NSString * _Nullable resultText, NSError * _Nullable error) {
					if (resultText) {
						[[LTTranslateManager sharedManager] translateAndPresent:resultText fromRect:selectionRectInWindow];
					}
				}];
			}]];
	}
	if ([[LTManager sharedManager] boolForKey:@"FreezeEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"freeze" icon:LTIcon(@"pause.circle")
			hintText:@"Freeze Screen" action:^{
				[[LTFreezeManager sharedManager] toggleFreeze];
			}]];
	}
	if ([[LTManager sharedManager] boolForKey:@"ScreenshotEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"screenshot" icon:LTIcon(@"camera")
			hintText:@"Screenshot" action:^{
				[[LTScreenshotManager sharedManager] captureRegion:selectionRectInWindow completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
					if (image) {
						[[LTScreenshotManager sharedManager] saveImageToPhotos:image completion:nil];
					}
				}];
			}]];
	}
	if ([[LTManager sharedManager] boolForKey:@"LongShotEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"longshot" icon:LTIcon(@"square.stack")
			hintText:@"Long Screenshot" action:^{
				// Extension point: bind to the nearest UIScrollView under
				// the selection point rather than a placeholder no-op.
			}]];
	}
	if ([[LTManager sharedManager] boolForKey:@"EditorEnabled" default:YES]) {
		[items addObject:[LTToolbarItem itemWithIdentifier:@"editor" icon:LTIcon(@"pencil.tip.crop.circle")
			hintText:@"Edit" action:^{
				[[LTScreenshotManager sharedManager] captureRegion:selectionRectInWindow completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
					if (image) {
						[[LTEditorManager sharedManager] beginEditingImage:image];
					}
				}];
			}]];
	}

	[gToolbar configureWithItems:items];
	[gToolbar presentAnchoredToSelectionRect:selectionRectInWindow inWindow:weakWindow ?: window];
}

#pragma mark - Hooks

%hook UIMenuController

- (void)setTargetRect:(CGRect)targetRect inView:(UIView *)targetView {
	%orig;
	if (![[LTManager sharedManager] isTweakEnabled]) return;
	if (!targetView.window) return;

	CGRect rectInWindow = [targetView convertRect:targetRect toView:nil];
	dispatch_async(dispatch_get_main_queue(), ^{
		LTShowToolbarForSelection(rectInWindow, targetView.window);
	});
}

%end

%ctor {
	@autoreleasepool {
		LTManager *manager = [LTManager sharedManager];

		// Register every feature module — extension point for future
		// modules: instantiate + registerModule: here.
		[manager registerModule:[LTFreezeManager sharedManager]];
		[manager registerModule:[LTScreenshotManager sharedManager]];
		[manager registerModule:[LTTranslateManager sharedManager]];
		[manager registerModule:[LTAIManager sharedManager]];
		[manager registerModule:[LTEditorManager sharedManager]];
		[manager registerModule:[LTLongShotManager sharedManager]];
		[manager registerModule:[LTSileoTranslateManager sharedManager]];

		[manager activateAllModules];
	}
}
