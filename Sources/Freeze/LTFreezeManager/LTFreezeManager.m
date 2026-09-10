#import "LTFreezeManager.h"

@interface LTFreezeManager ()
@property (nonatomic, strong) UIWindow *freezeWindow;
@property (nonatomic, strong) UIImageView *freezeImageView;
@property (nonatomic, assign) BOOL frozen;
@end

@implementation LTFreezeManager

+ (instancetype)sharedManager {
    static LTFreezeManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[LTFreezeManager alloc] init];
    });
    return shared;
}

- (void)activate {
}

- (void)deactivate {
    [self unfreeze];
}

- (UIImage *)snapshotOfKeyWindow {
    UIWindow *keyWindow = nil;

    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive) {
            continue;
        }

        for (UIWindow *window in scene.windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }

        if (keyWindow) {
            break;
        }
    }

    if (!keyWindow) {
        return nil;
    }

    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat preferredFormat];
    format.opaque = YES;

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc]
         initWithBounds:keyWindow.bounds
         format:format];

    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [keyWindow drawViewHierarchyInRect:keyWindow.bounds
                        afterScreenUpdates:NO];
    }];
}

- (void)freezeCurrentScreen {
    if (self.frozen) {
        return;
    }

    UIImage *snapshot = [self snapshotOfKeyWindow];
    if (!snapshot) {
        return;
    }

    UIWindowScene *scene = nil;

    for (UIWindowScene *windowScene in
         UIApplication.sharedApplication.connectedScenes) {

        if (windowScene.activationState ==
            UISceneActivationStateForegroundActive) {
            scene = windowScene;
            break;
        }
    }

    if (!scene) {
        return;
    }

    self.freezeWindow =
        [[UIWindow alloc] initWithWindowScene:scene];

    self.freezeWindow.frame =
        scene.coordinateSpace.bounds;

    self.freezeWindow.windowLevel =
        UIWindowLevelStatusBar + 1;

    self.freezeWindow.backgroundColor =
        UIColor.blackColor;

    self.freezeImageView =
        [[UIImageView alloc]
         initWithFrame:self.freezeWindow.bounds];

    self.freezeImageView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    self.freezeImageView.image = snapshot;
    self.freezeImageView.contentMode =
        UIViewContentModeScaleAspectFit;
    self.freezeImageView.userInteractionEnabled = YES;

    [self.freezeWindow addSubview:self.freezeImageView];

    UITapGestureRecognizer *doubleTap =
        [[UITapGestureRecognizer alloc]
         initWithTarget:self
         action:@selector(unfreeze)];

    doubleTap.numberOfTapsRequired = 2;

    [self.freezeImageView addGestureRecognizer:doubleTap];

    self.freezeWindow.hidden = NO;
    self.frozen = YES;
}

- (void)unfreeze {
    if (!self.frozen) {
        return;
    }

    UIWindow *window = self.freezeWindow;

    self.frozen = NO;
    self.freezeWindow = nil;
    self.freezeImageView = nil;

    [UIView animateWithDuration:0.2
                     animations:^{
        window.alpha = 0.0;
    }
                     completion:^(BOOL finished) {
        window.hidden = YES;
    }];
}

- (void)toggleFreeze {
    if (self.frozen) {
        [self unfreeze];
    } else {
        [self freezeCurrentScreen];
    }
}

@end
