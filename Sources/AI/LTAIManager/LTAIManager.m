#import "LTAIManager.h"

@implementation LTAIManager

+ (instancetype)sharedManager {
    static LTAIManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LTAIManager alloc] init];
    });
    return shared;
}

- (void)activate {
}

- (void)deactivate {
}

- (void)runAction:(LTAIAction)action
           onText:(NSString *)text
       completion:(void (^)(NSString *resultText, NSError *error))completion {

    if (text.length == 0) {
        if (completion) {
            completion(@"", nil);
        }
        return;
    }

    NSString *prompt = [self promptForAction:action text:text];

    NSString *provider =
        [[NSUserDefaults standardUserDefaults]
         stringForKey:@"AIProvider"];

    if (provider.length == 0) {
        provider = @"local";
    }

    if ([provider isEqualToString:@"local"]) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSString *result =
                [NSString stringWithFormat:
                 @"AI 未配置。\n\n%@", prompt];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(result, nil);
                }
            });
        });
        return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *result =
            [NSString stringWithFormat:
             @"已提交给 %@。\n\n%@", provider, prompt];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(result, nil);
            }
        });
    });
}

- (NSString *)promptForAction:(LTAIAction)action
                         text:(NSString *)text {

    switch (action) {
        case LTAIActionSummarize:
            return [NSString stringWithFormat:
                    @"请总结以下内容：\n%@",
                    text];

        case LTAIActionExplain:
            return [NSString stringWithFormat:
                    @"请解释以下内容：\n%@",
                    text];

        case LTAIActionRewrite:
            return [NSString stringWithFormat:
                    @"请润色以下内容：\n%@",
                    text];

        default:
            return text;
    }
}

@end
