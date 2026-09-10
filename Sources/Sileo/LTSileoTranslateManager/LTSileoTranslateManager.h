// LTSileoTranslateManager.h
// Injects a translate action into Sileo package-detail views: finds
// description/label text within a given view hierarchy and routes it
// through LTTranslateManager, then swaps the label text in place.
//
// Extension point: -localizableLabelsInView: is a generic UILabel/
// UITextView walker; tighten it to Sileo's actual class names
// (discovered at runtime via class-dump) once hooking Sileo directly
// from Tweak.x's per-app filter.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTSileoTranslateManager : NSObject <LTModule>

+ (instancetype)sharedManager;

// Walks `rootView`'s subtree, translating any UILabel/UITextView text
// found, replacing it in place. Intended to be invoked from a Sileo
// view-controller hook (e.g. -viewDidAppear:) registered in Tweak.x.
- (void)translateLabelsInView:(UIView *)rootView;

// Returns all text-bearing leaf views under rootView — the extension
// point for future filtering (e.g. skip version numbers, skip prices).
- (NSArray<UIView *> *)localizableLabelsInView:(UIView *)rootView;

@end

NS_ASSUME_NONNULL_END
