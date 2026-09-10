// LTOCRManager.m
#import "LTOCRManager.h"
#import <Vision/Vision.h>

@implementation LTOCRManager

+ (instancetype)sharedManager {
	static LTOCRManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTOCRManager alloc] init]; });
	return shared;
}

#pragma mark - LTModule

- (void)activate {
	// Stateless; OCR is invoked on-demand from the freeze toolbar.
}

- (void)deactivate {
	// Nothing to tear down.
}

#pragma mark - Public

- (void)recognizeTextInImage:(UIImage *)image completion:(LTOCRCompletion)completion {
	if (!image) {
		NSError *error = [NSError errorWithDomain:@"LTOCRManager" code:1
			userInfo:@{NSLocalizedDescriptionKey: @"Input image is nil"}];
		completion(nil, error);
		return;
	}

	CGImageRef cgImage = image.CGImage;
	if (!cgImage) {
		NSError *error = [NSError errorWithDomain:@"LTOCRManager" code:2
			userInfo:@{NSLocalizedDescriptionKey: @"Could not get CGImage from input"}];
		completion(nil, error);
		return;
	}

	VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
		if (error) {
			completion(nil, error);
			return;
		}

		NSArray<VNRecognizedTextObservation *> *observations = request.results;
		if (observations.count == 0) {
			// No text found is not an error; return empty string so callers
			// can distinguish "no text" from "OCR failed".
			completion(@"", nil);
			return;
		}

		NSMutableArray<NSString *> *lines = [NSMutableArray array];
		for (VNRecognizedTextObservation *observation in observations) {
			NSArray<VNRecognizedText *> *candidates = [observation topCandidates:1];
			if (candidates.count > 0) {
				[lines addObject:candidates[0].string];
			}
		}

		NSString *result = [lines componentsJoinedByString:@"\n"];
		completion(result, nil);
	}];

	// Use accurate recognition; the freeze overlay means latency is acceptable.
	request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
	request.usesLanguageCorrection = YES;
	// Recognize English and Simplified Chinese by default.
	request.recognitionLanguages = @[@"en-US", @"zh-Hans"];

	VNImageRequestHandler *handler = [[VNImageRequestHandler alloc]
		initWithCGImage:cgImage options:@{}];

	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		NSError *handlerError = nil;
		[handler performRequests:@[request] error:&handlerError];
		if (handlerError) {
			completion(nil, handlerError);
		}
	});
}

@end
