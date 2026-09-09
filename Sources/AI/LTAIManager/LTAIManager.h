// LTAIManager.h
// AI-assist module: summarize / rewrite / explain / custom-prompt
// actions on selected text, dispatched through a pluggable
// LTAIProvider so any backend (on-device model, OpenAI-compatible
// endpoint, Anthropic-compatible endpoint, etc.) can be dropped in.
//
// Extension point: add cases to LTAIAction and matching prompt
// templates in -promptForAction:text: without touching call sites.

#import <Foundation/Foundation.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LTAIAction) {
	LTAIActionSummarize = 0,
	LTAIActionExplain,
	LTAIActionRewrite,
	LTAIActionCustomPrompt,
};

typedef void (^LTAICompletion)(NSString * _Nullable resultText, NSError * _Nullable error);

@protocol LTAIProvider <NSObject>
- (void)sendPrompt:(NSString *)prompt completion:(LTAICompletion)completion;
@end

@interface LTAIManager : NSObject <LTModule>

+ (instancetype)sharedManager;

@property (nonatomic, strong, nullable) id<LTAIProvider> provider;

// Runs a built-in action (summarize/explain/rewrite) over selectedText.
- (void)runAction:(LTAIAction)action onText:(NSString *)selectedText completion:(LTAICompletion)completion;

// Runs an arbitrary user-supplied prompt with selectedText as context.
- (void)runCustomPrompt:(NSString *)userPrompt onText:(NSString *)selectedText completion:(LTAICompletion)completion;

@end

NS_ASSUME_NONNULL_END
