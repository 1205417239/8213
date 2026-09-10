// LTSileoTranslateManager.m
#import "LTSileoTranslateManager.h"
#import "LTTranslateManager.h"

@interface LTSileoTranslateManager ()
@property (nonatomic, strong) NSMapTable<UIView *, NSString *> *originalTextByView;
// Fix: private selector called in -localizableLabelsInView: before definition.
- (void)collectLabelsFrom:(UIView *)view into:(NSMutableArray<UIView *> *)results;
@end

@implementation LTSileoTranslateManager

+ (instancetype)sharedManager {
	static LTSileoTranslateManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTSileoTranslateManager alloc] init]; });
	return shared;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_originalTextByView = [NSMapTable weakToStrongObjectsMapTable];
	}
	return self;
}

#pragma mark - LTModule

- (void)activate {
	// Hooked lazily: Tweak.x's Sileo view-controller %hook calls
	// -translateLabelsInView: directly when this module is enabled.
}

- (void)deactivate {
	[self.originalTextByView removeAllObjects];
}

#pragma mark - Public

- (NSArray<UIView *> *)localizableLabelsInView:(UIView *)rootView {
	NSMutableArray<UIView *> *results = [NSMutableArray array];
	[self collectLabelsFrom:rootView into:results];
	return results;
}

- (void)collectLabelsFrom:(UIView *)view into:(NSMutableArray<UIView *> *)results {
	if ([view isKindOfClass:[UILabel class]] || [view isKindOfClass:[UITextView class]]) {
		[results addObject:view];
	}
	for (UIView *subview in view.subviews) {
		[self collectLabelsFrom:subview into:results];
	}
}

- (nullable NSString *)textOf:(UIView *)view {
	if ([view isKindOfClass:[UILabel class]]) {
		return ((UILabel *)view).text;
	}
	if ([view isKindOfClass:[UITextView class]]) {
		return ((UITextView *)view).text;
	}
	return nil;
}

- (void)setText:(NSString *)text on:(UIView *)view {
	if ([view isKindOfClass:[UILabel class]]) {
		((UILabel *)view).text = text;
	} else if ([view isKindOfClass:[UITextView class]]) {
		((UITextView *)view).text = text;
	}
}

- (void)translateLabelsInView:(UIView *)rootView {
	if (![[LTManager sharedManager] boolForKey:@"SileoTranslateEnabled" default:NO]) return;

	NSArray<UIView *> *labels = [self localizableLabelsInView:rootView];
	NSString *targetLanguage = NSLocale.currentLocale.languageCode ?: @"en";

	for (UIView *label in labels) {
		NSString *original = [self textOf:label];
		if (original.length < 2) continue; // skip empty/trivial (icons, badges)

		if (![self.originalTextByView objectForKey:label]) {
			[self.originalTextByView setObject:original forKey:label];
		}

		__weak UIView *weakLabel = label;
		[[LTTranslateManager sharedManager] translateText:original targetLanguage:targetLanguage completion:^(NSString * _Nullable translatedText, NSError * _Nullable error) {
			if (!translatedText || error) return;
			UIView *strongLabel = weakLabel;
			if (!strongLabel) return;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self setText:translatedText on:strongLabel];
			});
		}];
	}
}

@end
