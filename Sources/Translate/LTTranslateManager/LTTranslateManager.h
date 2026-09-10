// LTTranslateManager.h
// Text translation module. Presents the sliding translate panel and
// dispatches to a pluggable engine chosen via preferences
// ("TranslateEngine": system | google | deepl | custom).
//
// Extension point: implement LTTranslateEngine for any new provider and
// register it in -engineForCurrentPreference without touching callers.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^LTTranslateCompletion)(NSString * _Nullable translatedText, NSError * _Nullable error);

// Conform to this to add a new translation backend.
@protocol LTTranslateEngine <NSObject>
- (void)translateText:(NSString *)text
        targetLanguage:(NSString *)targetLanguage
            completion:(LTTranslateCompletion)completion;
@end

@interface LTTranslateManager : NSObject <LTModule>

+ (instancetype)sharedManager;

// Runs translation through the currently-configured engine and shows
// the sliding translate panel with the result.
- (void)translateAndPresent:(NSString *)sourceText fromRect:(CGRect)anchorRect;

// Raw translation without UI, for reuse by AI / Editor / Sileo modules.
- (void)translateText:(NSString *)text
        targetLanguage:(NSString *)targetLanguage
            completion:(LTTranslateCompletion)completion;

@end

// Built-in stub engine: on-device NSLinguisticTagger language detect +
// a pass-through placeholder result. Wire up a real network engine by
// adding a new class conforming to LTTranslateEngine.
@interface LTSystemTranslateEngine : NSObject <LTTranslateEngine>
@end

NS_ASSUME_NONNULL_END
