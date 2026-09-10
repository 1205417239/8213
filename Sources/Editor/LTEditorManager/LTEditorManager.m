#import "LTEditorManager.h"

@implementation LTEditorOperation
@end

@interface LTEditorManager ()
@property (nonatomic, strong) NSMutableArray<LTEditorOperation *> *operations;
@end

@implementation LTEditorManager

+ (instancetype)sharedManager {
    static LTEditorManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LTEditorManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _operations = [NSMutableArray array];
    }
    return self;
}

- (void)activate {
}

- (void)deactivate {
    [self clearOperations];
    self.baseImage = nil;
}

- (void)beginEditingImage:(UIImage *)image {
    self.baseImage = image;
    [self clearOperations];
}

- (void)addOperation:(LTEditorOperation *)operation {
    if (operation) {
        [self.operations addObject:operation];
    }
}

- (void)undoLastOperation {
    if (self.operations.count > 0) {
        [self.operations removeLastObject];
    }
}

- (void)clearOperations {
    [self.operations removeAllObjects];
}

- (UIImage *)renderFinalImage {
    if (!self.baseImage) {
        return nil;
    }

    CGSize size = self.baseImage.size;
    CGRect canvas = CGRectMake(0, 0, size.width, size.height);

    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat preferredFormat];

    format.opaque = NO;

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc]
         initWithBounds:canvas
         format:format];

    UIImage *result =
        [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {

        [self.baseImage drawInRect:canvas];

        for (LTEditorOperation *operation in self.operations) {

            switch (operation.type) {

                case LTEditorOperationCrop:
                    break;

                case LTEditorOperationText: {
                    if (operation.text.length == 0) {
                        break;
                    }

                    NSDictionary *attributes = @{
                        NSFontAttributeName:
                            [UIFont systemFontOfSize:24
                                              weight:UIFontWeightBold],
                        NSForegroundColorAttributeName:
                            operation.color ?: UIColor.whiteColor
                    };

                    [operation.text drawInRect:operation.rect
                                withAttributes:attributes];
                    break;
                }

                case LTEditorOperationStroke: {
                    if (!operation.path) {
                        break;
                    }

                    UIColor *color =
                        operation.color ?: UIColor.redColor;

                    [color setStroke];

                    operation.path.lineWidth =
                        MAX(operation.path.lineWidth, 3.0);

                    [operation.path stroke];
                    break;
                }
            }
        }
    }];

    CGRect cropRect = canvas;

    for (LTEditorOperation *operation in self.operations) {
        if (operation.type == LTEditorOperationCrop) {
            cropRect =
                CGRectIntersection(operation.rect, canvas);
        }
    }

    if (!CGRectEqualToRect(cropRect, canvas) &&
        !CGRectIsEmpty(cropRect)) {

        CGFloat scale = result.scale;

        CGRect pixelRect = CGRectMake(
            cropRect.origin.x * scale,
            cropRect.origin.y * scale,
            cropRect.size.width * scale,
            cropRect.size.height * scale
        );

        CGImageRef imageRef =
            CGImageCreateWithImageInRect(
                result.CGImage,
                pixelRect
            );

        if (imageRef) {
            UIImage *cropped =
                [UIImage imageWithCGImage:imageRef
                                    scale:scale
                              orientation:result.imageOrientation];

            CGImageRelease(imageRef);

            return cropped;
        }
    }

    return result;
}

@end
