// LTTranslateManager.m
#import "LTTranslateManager.h"
#import "LTTranslatePanel.h"

@implementation LTSystemTranslateEngine

- (void)translateText:(NSString *)text
        targetLanguage:(NSString *)targetLanguage
            completion:(LTTranslateCompletion)completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *result = text.length ? text : @"";
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(result, nil);
        });
    });
}

@end

@interface LTTranslateManager ()
@property (nonatomic, strong) id<LTTranslateEngine> engine;
@property (nonatomic, strong) LTTranslatePanel *panel;
- (id<LTTranslateEngine>)engineForCurrentPreference;
- (NSString *)normalizedTargetLanguage:(NSString *)language;
@end

@implementation LTTranslateManager

+ (instancetype)sharedManager {
    static LTTranslateManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)activate {
    self.engine = [self engineForCurrentPreference];
}

- (void)deactivate {
    [self.panel dismiss];
    self.panel = nil;
    self.engine = nil;
}

- (void)reloadPreferences {
    self.engine = [self engineForCurrentPreference];
}

#pragma mark - Engine

- (id<LTTranslateEngine>)engineForCurrentPreference {
    NSString *choice =
        [[LTManager sharedManager] stringForKey:@"TranslateEngine"
                                       default:@"system"];

    if (choice.length == 0) {
        choice = @"system";
    }

    /*
     Providers can be registered here later:
       system / google / gemini / openai / openrouter / zhipu / custom

     Keep the manager independent from the provider implementation.
     */
    return [LTSystemTranslateEngine new];
}

#pragma mark - Language

- (NSString *)normalizedTargetLanguage:(NSString *)language {
    if (language.length == 0) {
        return @"zh-CN";
    }

    NSString *lower = language.lowercaseString;

    if ([lower isEqualToString:@"zh"] ||
        [lower isEqualToString:@"zh-cn"] ||
        [lower isEqualToString:@"zh-hans"]) {
        return @"zh-CN";
    }

    return language;
}

#pragma mark - Translation

- (void)translateText:(NSString *)text
        targetLanguage:(NSString *)targetLanguage
            completion:(LTTranslateCompletion)completion {

    if (text.length == 0) {
        NSError *error =
            [NSError errorWithDomain:@"LTTranslateManager"
                                code:1
                            userInfo:@{
                                NSLocalizedDescriptionKey : @"源文本为空"
                            }];

        if (completion) completion(nil, error);
        return;
    }

    if (!self.engine) {
        self.engine = [self engineForCurrentPreference];
    }

    NSString *language =
        [self normalizedTargetLanguage:targetLanguage];

    [self.engine translateText:text
                 targetLanguage:language
                     completion:completion];
}

- (void)translateAndPresent:(NSString *)sourceText
                   fromRect:(CGRect)anchorRect {

    if (sourceText.length == 0) {
        return;
    }

    if (!self.panel) {
        self.panel = [[LTTranslatePanel alloc] init];
    }

    [self.panel showLoadingFromRect:anchorRect];

    // LinguaTweak 默认目标语言：简体中文
    NSString *targetLanguage = @"zh-CN";

    [self translateText:sourceText
          targetLanguage:targetLanguage
              completion:^(NSString *translatedText,
                           NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self.panel showError:error.localizedDescription];
                return;
            }

            if (translatedText.length == 0) {
                [self.panel showError:@"翻译结果为空"];
                return;
            }

            [self.panel showResult:translatedText
                        sourceText:sourceText];
        });
    }];
}

@end
