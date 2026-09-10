#import "LTLongShotManager.h"

@interface LTLongShotManager ()
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *frames;
@property (nonatomic, assign) BOOL capturing;
@property (nonatomic, assign) CGFloat overlapTrim;
@end

@implementation LTLongShotManager

+ (instancetype)sharedManager {
    static LTLongShotManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LTLongShotManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _frames = [NSMutableArray array];
        _overlapTrim = 40.0;
    }
    return self;
}

- (void)activate {
}

- (void)deactivate {
    [self cancelSession];
}

- (void)beginSessionWithScrollView:(UIScrollView *)scrollView {
    [self cancelSession];

    self.scrollView = scrollView;
    self.capturing = YES;
    self.frames = [NSMutableArray array];
}

- (void)captureNextFrameWithProgress:
    (void (^)(CGFloat progress))progress {

    if (!self.capturing || !self.scrollView) {
        return;
    }

    CGRect rect =
        [self.scrollView convertRect:self.scrollView.bounds
                              toView:self.scrollView.window];

    [[LTScreenshotManager sharedManager]
     captureRegion:rect
     completion:^(UIImage *image, NSError *error) {

        if (!image || error || !self.capturing) {
            return;
        }

        [self.frames addObject:image];

        CGFloat maxOffset =
            MAX(1.0,
                self.scrollView.contentSize.height -
                self.scrollView.bounds.size.height);

        CGFloat progressValue =
            self.scrollView.contentOffset.y / maxOffset;

        if (progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(MIN(1.0, MAX(0.0, progressValue)));
            });
        }
    }];
}

- (void)finishSessionWithCompletion:
    (void (^)(UIImage *image, NSError *error))completion {

    if (!self.capturing) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LTLongShotManager"
                                                code:1
                                            userInfo:@{
                NSLocalizedDescriptionKey:
                    @"长截图会话未启动"
            }]);
        }
        return;
    }

    self.capturing = NO;

    UIImage *result = [self stitchFrames:self.frames];

    [self.frames removeAllObjects];
    self.scrollView = nil;

    if (completion) {
        completion(result, nil);
    }
}

- (void)cancelSession {
    self.capturing = NO;
    [self.frames removeAllObjects];
    self.scrollView = nil;
}

- (UIImage *)stitchFrames:(NSArray<UIImage *> *)frames {
    if (frames.count == 0) {
        return nil;
    }

    if (frames.count == 1) {
        return frames.firstObject;
    }

    CGFloat width = frames.firstObject.size.width;
    CGFloat totalHeight = 0;

    for (NSUInteger i = 0; i < frames.count; i++) {
        UIImage *image = frames[i];

        if (i == 0) {
            totalHeight += image.size.height;
        } else {
            totalHeight +=
                MAX(0, image.size.height - self.overlapTrim);
        }
    }

    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat preferredFormat];

    format.opaque = YES;

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc]
         initWithSize:CGSizeMake(width, totalHeight)
         format:format];

    return [renderer imageWithActions:
        ^(UIGraphicsImageRendererContext *context) {

        CGFloat y = 0;

        for (NSUInteger i = 0; i < frames.count; i++) {
            UIImage *image = frames[i];

            CGRect drawRect;

            if (i == 0) {
                drawRect =
                    CGRectMake(0,
                               y,
                               image.size.width,
                               image.size.height);
            } else {
                CGFloat cropTop =
                    MIN(self.overlapTrim,
                        image.size.height);

                CGRect sourceRect =
                    CGRectMake(0,
                               cropTop,
                               image.size.width,
                               image.size.height - cropTop);

                CGFloat drawHeight = sourceRect.size.height;

                drawRect =
                    CGRectMake(0,
                               y,
                               image.size.width,
                               drawHeight);

                [image drawInRect:drawRect
                         blendMode:kCGBlendModeNormal
                             alpha:1.0];

                y += drawHeight;
                continue;
            }

            [image drawInRect:drawRect
                     blendMode:kCGBlendModeNormal
                         alpha:1.0];

            y += drawRect.size.height;
        }
    }];
}

@end
