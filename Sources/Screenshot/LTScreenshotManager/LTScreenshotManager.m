#import "LTScreenshotManager.h"
#import <Photos/Photos.h>

@implementation LTScreenshotManager

+ (instancetype)sharedManager {
    static LTScreenshotManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LTScreenshotManager alloc] init];
    });
    return shared;
}

- (void)activate {
}

- (void)deactivate {
}

- (UIWindow *)currentKeyWindow {
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive) {
            continue;
        }

        for (UIWindow *window in scene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }

    return nil;
}

- (void)captureFullScreen:(LTScreenshotCompletion)completion {
    [self captureRegion:CGRectNull completion:completion];
}

- (void)captureRegion:(CGRect)region
           completion:(LTScreenshotCompletion)completion {
    UIWindow *window = [self currentKeyWindow];

    if (!window) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LTScreenshotManager"
                                                 code:1
                                             userInfo:@{
                NSLocalizedDescriptionKey: @"没有可用的当前窗口"
            }]);
        }
        return;
    }

    CGRect captureRect =
        CGRectIsNull(region)
        ? window.bounds
        : CGRectIntersection(region, window.bounds);

    if (CGRectIsEmpty(captureRect)) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LTScreenshotManager"
                                                 code:2
                                             userInfo:@{
                NSLocalizedDescriptionKey: @"截图区域为空"
            }]);
        }
        return;
    }

    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat preferredFormat];

    format.opaque = NO;

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc]
         initWithBounds:window.bounds
         format:format];

    UIImage *image =
        [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [window drawViewHierarchyInRect:window.bounds
                         afterScreenUpdates:NO];
        }];

    if (CGRectEqualToRect(captureRect, window.bounds)) {
        if (completion) {
            completion(image, nil);
        }
        return;
    }

    CGFloat scale = image.scale;

    CGRect pixelRect = CGRectMake(
        captureRect.origin.x * scale,
        captureRect.origin.y * scale,
        captureRect.size.width * scale,
        captureRect.size.height * scale
    );

    CGImageRef croppedRef =
        CGImageCreateWithImageInRect(image.CGImage, pixelRect);

    if (!croppedRef) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LTScreenshotManager"
                                                 code:4
                                             userInfo:@{
                NSLocalizedDescriptionKey: @"无法裁剪截图"
            }]);
        }
        return;
    }

    UIImage *cropped =
        [UIImage imageWithCGImage:croppedRef
                             scale:scale
                       orientation:image.imageOrientation];

    CGImageRelease(croppedRef);

    if (completion) {
        completion(cropped, nil);
    }
}

- (void)saveImageToPhotos:(UIImage *)image
                completion:(void (^)(BOOL success,
                                     NSError * _Nullable error))completion {
    if (!image) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"LTScreenshotManager"
                                               code:5
                                           userInfo:@{
                NSLocalizedDescriptionKey: @"截图为空"
            }]);
        }
        return;
    }

    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly
                                               handler:
     ^(PHAuthorizationStatus status) {

        if (status != PHAuthorizationStatusAuthorized &&
            status != PHAuthorizationStatusLimited) {

            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, [NSError errorWithDomain:
                                    @"LTScreenshotManager"
                                                             code:3
                                                         userInfo:@{
                        NSLocalizedDescriptionKey:
                            @"没有获得照片访问权限"
                    }]);
                });
            }
            return;
        }

        [[PHPhotoLibrary sharedPhotoLibrary]
         performChanges:^{
            [PHAssetChangeRequest
             creationRequestForAssetFromImage:image];
        }
         completionHandler:^(BOOL success, NSError *error) {

            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(success, error);
                });
            }
        }];
    }];
}

@end
