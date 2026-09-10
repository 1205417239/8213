// LTRegionSelectView.h
// Overlay view for selecting a rectangular region on the frozen screen.
// Supports dragging the whole region to move it, and 8 resize handles
// (4 corners + 4 edge midpoints) to change its size.
//
// This view is transparent except for the selection border and handles;
// it is meant to be added on top of the frozen snapshot image view.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTRegionSelectView : UIView

// Current selected region in the superview's coordinate system.
// Setting this updates the UI immediately; the setter clamps to bounds.
@property (nonatomic, assign) CGRect selectedRegion;

// Called whenever the user moves or resizes the region.
@property (nonatomic, copy, nullable) void (^regionDidChangeBlock)(CGRect region);

// Minimum selectable size (width/height) in points.
@property (nonatomic, assign) CGFloat minimumRegionSize; // default 40pt

- (instancetype)initWithFrame:(CGRect)frame initialRegion:(CGRect)initialRegion;

@end

NS_ASSUME_NONNULL_END
