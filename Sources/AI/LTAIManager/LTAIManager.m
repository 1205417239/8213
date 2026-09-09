// LTAIManager.m
#import "LTAIManager.h"

// Placeholder provider so the pipeline is exercisable without network
// credentials configured. Real deployments should set
// LTAIManager.sharedManager.provider to a concrete LTAIProvider that
// talks to the desired backend.
@interface LTAILocalEchoProvider : NSObject <LTAIProvider>
@end

@implementation LTAILocalEchoProvider

- (void)sendPrompt:(NSString *)prompt completion:(LTAICompletion)completion {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *result = [NSString stringWithFormat:@"(AI provider not configured)\n\nPrompt received:\n%@", prompt];
		dispatch_async(dispatch_get_main_queue(), ^{
			completion(result, nil);
		});
	});
}

@end

@implementation LTAIManager

+ (instancetype)sharedManager {
	static LTAIManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTAIManager alloc] init]; });
	return shared;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_provider = [LTAILocalEchoProvider new];
	}
	return self;
}

#pragma mark - LTModule

- (void)activate {
	// Provider is lazily invoked per-request; nothing to hook eagerly.
}

- (void)deactivate {
	// No persistent state.
}

#pragma mark - Prompt templates

- (NSString *)promptForAction:(LTAIAction)action text:(NSString *)text {
	switch (action) {
		case LTAIActionSummarize:
			return [NSString stringWithFormat:@"Summarize the following text concisely:\n\n%@", text];
		case LTAIActionExplain:
			return [NSString stringWithFormat:@"Explain the following text in simple terms:\n\n%@", text];
		case LTAIActionRewrite:
			return [NSString stringWithFormat:@"Rewrite the following text more clearly:\n\n%@", text];
		case LTAIActionCustomPrompt:
		default:
			return text;
	}
}

#pragma mark - Public

- (void)runAction:(LTAIAction)action onText:(NSString *)selectedText completion:(LTAICompletion)completion {
	if (selectedText.length == 0) {
		NSError *error = [NSError errorWithDomain:@"LTAIManager" code:1
			userInfo:@{NSLocalizedDescriptionKey: @"No text selected"}];
		completion(nil, error);
		return;
	}
	NSString *prompt = [self promptForAction:action text:selectedText];
	[self.provider sendPrompt:prompt completion:completion];
}

- (void)runCustomPrompt:(NSString *)userPrompt onText:(NSString *)selectedText completion:(LTAICompletion)completion {
	NSString *combined = selectedText.length > 0
		? [NSString stringWithFormat:@"%@\n\nContext:\n%@", userPrompt, selectedText]
		: userPrompt;
	[self.provider sendPrompt:combined completion:completion];
}

@end
