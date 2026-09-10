#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTFreezeManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly, getter=isFrozen) BOOL frozen;

/**
 * 开始冻结当前屏幕。
 *
 * 流程：
 * 1. 获取当前屏幕图像
 * 2. 创建独立冻结窗口
 * 3. 显示冻结画面
 * 4. 进入区域选择状态
 */
- (void)startFreeze;

/**
 * 结束冻结并移除冻结窗口。
 */
- (void)stopFreeze;

/**
 * 开始/结束冻结。
 */
- (void)toggleFreeze;

/**
 * 当前冻结画面的截图。
 */
- (nullable UIImage *)currentFreezeImage;

/**
 * 当前用户选择的区域。
 */
- (CGRect)selectedRegion;

/**
 * 设置当前选择区域。
 */
- (void)setSelectedRegion:(CGRect)region;

/**
 * 从当前冻结画面取得选区图片。
 */
- (nullable UIImage *)selectedRegionImage;

@end

NS_ASSUME_NONNULL_END
