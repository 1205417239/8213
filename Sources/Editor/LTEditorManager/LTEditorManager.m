// LTEditorManager.m
#import "LTEditorManager.h"

@implementation LTEditorOperation
@end

@interface LTEditorManager ()
@property (nonatomic, strong) NSMutableArray<LTEditorOperation *> *operations;
@end

@implementation LTEditorManager

+ (instancetype)sharedManager {
	static LTEditorManager *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ shared = [[LTEditorManager alloc] init]; });
	return shared;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_operations = [NSMutableArray array];
	}
	return self;
}

#pragma mark - LTModule

- (void)activate {}
- (void)deactivate { [self clearOperations]; self.baseImage = nil; }

#pragma mark - Public

- (void)beginEditingImage:(UIImage *)image {
	self.baseImage = image;
	[self clearOperations];
}

- (void)addOperation:(LTEditorOperation *)operation {
	[self.operations addObject:operation];
}

- (void)undoLastOperation {
	if (self.operations.count > 0) {
		[self.operations removeLastObject];
	}
}

- (void)clearOperations {
	[self.operations removeAllObjects];
}

- (nullable UIImage *)renderFinalImage {
	if (!self.baseImage) return nil;

	CGRect canvasRect = CGRectMake(0, 0, self.baseImage.size.width, self.baseImage.size.height);

	// Apply crop operations first (last crop wins), then draw the rest.
	CGRect cropRect = canvasRect;
	for (LTEditorOperation *op in self.operations) {
		if (op.type == LTEditorOperationCrop) {
			cropRect = CGRectIntersection(op.rect, canvasRect);
		}
	}

	UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
	format.opaque = NO;
	UIGraphicsImageRenderer *renderer =
		[[UIGraphicsImageRenderer alloc] initWithBounds:canvasRect format:format];

	UIImage *composited = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull ctx) {
		[self.baseImage drawInRect:canvasRect];

		for (LTEditorOperation *op in self.operations) {
			switch (op.type) {
				case LTEditorOperationCrop:
					break; // handled via final crop below
				case LTEditorOperationText: {
					if (op.text.length == 0) break;
					NSDictionary *attrs = @{
						NSFontAttributeName: [UIFont boldSystemFontOfSize:24],
						NSForegroundColorAttributeName: op.color ?: UIColor.whiteColor,
					};
					[op.text drawInRect:op.rect withAttributes:attrs];
					break;
				}
				case LTEditorOperationStroke: {
					if (!op.path) break;
					[(op.color ?: UIColor.redColor) setStroke];
					op.path.lineWidth = MAX(op.path.lineWidth, 3.0);
					[op.path stroke];
					break;
				}
			}
		}
	}];

	if (!CGRectEqualToRect(cropRect, canvasRect) && !CGRectIsEmpty(cropRect)) {
		CGImageRef croppedRef = CGImageCreateWithImageInRect(composited.CGImage, cropRect);
		UIImage *cropped = [UIImage imageWithCGImage:croppedRef scale:composited.scale orientation:composited.imageOrientation];
		CGImageRelease(croppedRef);
		return cropped;
	}

	return composited;
}

@end
