// LTOCRManager.h
// On-device OCR module using Apple's Vision framework (VNRecognizeTextRequest).
// Takes a UIImage (typically the cropped selected region from LTFreezeManager)
// and returns recognized text as a single concatenated string.
//
// This is the OCR step in the call chain:
//   Toolbar -> LTOCRManager recognizeTextInImage -> text result
//   -> LTTranslateManager / LTAIManager
//
// Extension point: replace Vision with Tesseract or a cloud OCR backend
// by implementing the same completion-block signature.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^LTOCRCompletion)(NSString * _Nullable text, NSError * _Nullable error);

@interface LTOCRManager : NSObject <LTModule>

+ (instancetype)sharedManager;

// Recognizes text in `image` using the Vision framework. The completion
// block is called on a background queue; dispatch to main before touching UI.
- (void)recognizeTextInImage:(UIImage *)image completion:(LTOCRCompletion)completion;

@end

NS_ASSUME_NONNULL_END
