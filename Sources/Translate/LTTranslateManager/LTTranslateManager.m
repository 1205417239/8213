// LTTranslateManager.m
#import "LTTranslateManager.h"
#import "LTTranslatePanel.h"

@implementation LTSystemTranslateEngine
- (void)translateText:(NSString *)text
        targetLanguage:(NSString *)targetLanguage
            completion:(LTTranslateCompletion)completion {
	// The "system" engine is a placeholder slot. A real implementation
	// would use iOS 17's Translation framework or a configured network
	// API. Until a real engine is wired in, return an explicit error so
	// callers never mistake echo output for a real translation.
	NSError *error = [NSError errorWithDomain:@"LTTranslateManager" code:10
		userInfo:@{NSLocalizedDescriptionKey: @"Translation engine not configured. Choose Google/DeepL/Custom in settings and provide API credentials."}];
	dispatch_async(dispatch_get_main_queue(), ^{
		completion(nil, error);
	});
}
@end

@interface LTTranslateManager ()
@property (nonatomic, strong) id<LTTranslateEngine> engine;
@property (nonatomic, strong) LTTranslatePanel *panel;
// Fix: private selector used in -activate/-reloadPreferences before its
// implementation below; forward-declare for ARC message dispatch.
- (id<LTTranslateEngine>)engineForCurrentPreference;
@end

@implementation LTTranslateManager
+ (instancetype)sharedManager {
	static LTTranslateManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTTranslateManager alloc] init]; });
	return shared;
}
#pragma mark - LTModule

- (void)activate {
	self.engine = [self engineForCurrentPreference];
}

- (void)deactivate {
	[self.panel dismiss];
	self.panel = nil;
}

- (void)reloadPreferences {
	self.engine = [self engineForCurrentPreference];
}
#pragma mark - Engine selection

- (id<LTTranslateEngine>)engineForCurrentPreference {
	NSString *choice = [[LTManager sharedManager] stringForKey:@"TranslateEngine" default:@"system"];
	// Extension point: add `else if ([choice isEqualToString:@"google"])`
	// etc. once concrete network engines are implemented.
	if ([choice isEqualToString:@"system"]) {
		return [LTSystemTranslateEngine new];
	}
	return [LTSystemTranslateEngine new];
}
#pragma mark - Public

- (void)translateText:(NSString *)text
        targetLanguage:(NSString *)targetLanguage
            completion:(LTTranslateCompletion)completion {
	if (text.length == 0) {
		NSError *error = [NSError errorWithDomain:@"LTTranslateManager" code:1
			userInfo:@{NSLocalizedDescriptionKey: @"源文本为空"}];
		completion(nil, error);
		return;
	}
	[self.engine translateText:text targetLanguage:targetLanguage completion:completion];
}

- (void)translateAndPresent:(NSString *)sourceText fromRect:(CGRect)anchorRect {
	if (!self.panel) {
		self.panel = [[LTTranslatePanel alloc] init];
	}
	[self.panel showLoadingFromRect:anchorRect];
	NSString *targetLanguage = NSLocale.currentLocale.languageCode ?: @"en";
	[self translateText:sourceText targetLanguage:targetLanguage completion:^(NSString * _Nullable translatedText, NSError * _Nullable error) {
		if (error) {
			[self.panel showError:error.localizedDescription];
			return;
		}
		[self.panel showResult:translatedText sourceText:sourceText];
	}];
}

@end
