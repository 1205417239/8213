// LTRegionSelectView.m
#import "LTRegionSelectView.h"

static const CGFloat kLTHandleSize = 22.0;
static const CGFloat kLTBorderWidth = 1.5;

typedef NS_ENUM(NSInteger, LTDragMode) {
	LTDragModeNone = 0,
	LTDragModeMove,
	LTDragModeTopLeft,
	LTDragModeTopRight,
	LTDragModeBottomLeft,
	LTDragModeBottomRight,
	LTDragModeTop,
	LTDragModeBottom,
	LTDragModeLeft,
	LTDragModeRight,
};

@interface LTRegionSelectView ()
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) NSMutableArray<UIView *> *handleViews;
@property (nonatomic, assign) LTDragMode dragMode;
@property (nonatomic, assign) CGPoint dragStartPoint;
@property (nonatomic, assign) CGRect dragStartRegion;
@end

@implementation LTRegionSelectView

- (instancetype)initWithFrame:(CGRect)frame initialRegion:(CGRect)initialRegion {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = UIColor.clearColor;
		self.userInteractionEnabled = YES;
		_minimumRegionSize = 40.0;
		_dragMode = LTDragModeNone;
		_handleViews = [NSMutableArray array];

		// Selection border
		_borderView = [[UIView alloc] init];
		_borderView.backgroundColor = [UIColor.clearColor colorWithAlphaComponent:0.0];
		_borderView.layer.borderColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0].CGColor;
		_borderView.layer.borderWidth = kLTBorderWidth;
		_borderView.userInteractionEnabled = NO;
		[self addSubview:_borderView];

		// 8 handles: TL, TR, BL, BR, T, B, L, R
		for (NSInteger i = 0; i < 8; i++) {
			UIView *handle = [[UIView alloc] init];
			handle.backgroundColor = UIColor.whiteColor;
			handle.layer.borderColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0].CGColor;
			handle.layer.borderWidth = 1.5;
			handle.layer.cornerRadius = kLTHandleSize / 2.0;
			handle.userInteractionEnabled = NO;
			[self addSubview:handle];
			[_handleViews addObject:handle];
		}

		_selectedRegion = CGRectIsNull(initialRegion) ? CGRectInset(self.bounds, 60, 120) : initialRegion;
		[self layoutSelection];
	}
	return self;
}

#pragma mark - Layout

- (void)layoutSelection {
	self.borderView.frame = self.selectedRegion;

	// Handle positions: 0=TL, 1=TR, 2=BL, 3=BR, 4=T, 5=B, 6=L, 7=R
	CGRect r = self.selectedRegion;
	CGFloat hs = kLTHandleSize;
	NSArray *values = @[
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMinX(r) - hs/2, CGRectGetMinY(r) - hs/2, hs, hs)], // TL
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMaxX(r) - hs/2, CGRectGetMinY(r) - hs/2, hs, hs)], // TR
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMinX(r) - hs/2, CGRectGetMaxY(r) - hs/2, hs, hs)], // BL
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMaxX(r) - hs/2, CGRectGetMaxY(r) - hs/2, hs, hs)], // BR
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMidX(r) - hs/2, CGRectGetMinY(r) - hs/2, hs, hs)], // T
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMidX(r) - hs/2, CGRectGetMaxY(r) - hs/2, hs, hs)], // B
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMinX(r) - hs/2, CGRectGetMidY(r) - hs/2, hs, hs)], // L
		[NSValue valueWithCGRect:CGRectMake(CGRectGetMaxX(r) - hs/2, CGRectGetMidY(r) - hs/2, hs, hs)], // R
	];
	for (NSInteger i = 0; i < self.handleViews.count && i < values.count; i++) {
		self.handleViews[i].frame = [values[i] CGRectValue];
	}
}

- (void)setSelectedRegion:(CGRect)selectedRegion {
	// Clamp to bounds
	CGRect bounds = self.bounds;
	CGFloat minX = MAX(CGRectGetMinX(selectedRegion), CGRectGetMinX(bounds));
	CGFloat minY = MAX(CGRectGetMinY(selectedRegion), CGRectGetMinY(bounds));
	CGFloat maxX = MIN(CGRectGetMaxX(selectedRegion), CGRectGetMaxX(bounds));
	CGFloat maxY = MIN(CGRectGetMaxY(selectedRegion), CGRectGetMaxY(bounds));
	CGFloat w = MAX(maxX - minX, self.minimumRegionSize);
	CGFloat h = MAX(maxY - minY, self.minimumRegionSize);
	// Re-clamp after enforcing minimum size
	if (minX + w > CGRectGetMaxX(bounds)) minX = CGRectGetMaxX(bounds) - w;
	if (minY + h > CGRectGetMaxY(bounds)) minY = CGRectGetMaxY(bounds) - h;
	if (minX < CGRectGetMinX(bounds)) minX = CGRectGetMinX(bounds);
	if (minY < CGRectGetMinY(bounds)) minY = CGRectGetMinY(bounds);

	_selectedRegion = CGRectMake(minX, minY, w, h);
	[self layoutSelection];
}

#pragma mark - Touch handling

- (LTDragMode)dragModeAtPoint:(CGPoint)point {
	// Check handles first (from outside in)
	CGRect r = self.selectedRegion;
	CGFloat hit = kLTHandleSize;

	CGRect tl = CGRectMake(CGRectGetMinX(r) - hit/2, CGRectGetMinY(r) - hit/2, hit, hit);
	CGRect tr = CGRectMake(CGRectGetMaxX(r) - hit/2, CGRectGetMinY(r) - hit/2, hit, hit);
	CGRect bl = CGRectMake(CGRectGetMinX(r) - hit/2, CGRectGetMaxY(r) - hit/2, hit, hit);
	CGRect br = CGRectMake(CGRectGetMaxX(r) - hit/2, CGRectGetMaxY(r) - hit/2, hit, hit);
	CGRect t  = CGRectMake(CGRectGetMidX(r) - hit/2, CGRectGetMinY(r) - hit/2, hit, hit);
	CGRect b  = CGRectMake(CGRectGetMidX(r) - hit/2, CGRectGetMaxY(r) - hit/2, hit, hit);
	CGRect l  = CGRectMake(CGRectGetMinX(r) - hit/2, CGRectGetMidY(r) - hit/2, hit, hit);
	CGRect ri = CGRectMake(CGRectGetMaxX(r) - hit/2, CGRectGetMidY(r) - hit/2, hit, hit);

	if (CGRectContainsPoint(tl, point)) return LTDragModeTopLeft;
	if (CGRectContainsPoint(tr, point)) return LTDragModeTopRight;
	if (CGRectContainsPoint(bl, point)) return LTDragModeBottomLeft;
	if (CGRectContainsPoint(br, point)) return LTDragModeBottomRight;
	if (CGRectContainsPoint(t, point))  return LTDragModeTop;
	if (CGRectContainsPoint(b, point))  return LTDragModeBottom;
	if (CGRectContainsPoint(l, point))  return LTDragModeLeft;
	if (CGRectContainsPoint(ri, point)) return LTDragModeRight;

	// Check inside region for move
	if (CGRectContainsPoint(r, point)) return LTDragModeMove;

	return LTDragModeNone;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	self.dragMode = [self dragModeAtPoint:point];
	if (self.dragMode != LTDragModeNone) {
		self.dragStartPoint = point;
		self.dragStartRegion = self.selectedRegion;
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (self.dragMode == LTDragModeNone) return;

	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	CGFloat dx = point.x - self.dragStartPoint.x;
	CGFloat dy = point.y - self.dragStartPoint.y;
	CGRect r = self.dragStartRegion;
	CGRect newRegion = r;

	switch (self.dragMode) {
		case LTDragModeMove:
			newRegion = CGRectOffset(r, dx, dy);
			break;
		case LTDragModeTopLeft:
			newRegion = CGRectMake(r.origin.x + dx, r.origin.y + dy,
				r.size.width - dx, r.size.height - dy);
			break;
		case LTDragModeTopRight:
			newRegion = CGRectMake(r.origin.x, r.origin.y + dy,
				r.size.width + dx, r.size.height - dy);
			break;
		case LTDragModeBottomLeft:
			newRegion = CGRectMake(r.origin.x + dx, r.origin.y,
				r.size.width - dx, r.size.height + dy);
			break;
		case LTDragModeBottomRight:
			newRegion = CGRectMake(r.origin.x, r.origin.y,
				r.size.width + dx, r.size.height + dy);
			break;
		case LTDragModeTop:
			newRegion = CGRectMake(r.origin.x, r.origin.y + dy,
				r.size.width, r.size.height - dy);
			break;
		case LTDragModeBottom:
			newRegion = CGRectMake(r.origin.x, r.origin.y,
				r.size.width, r.size.height + dy);
			break;
		case LTDragModeLeft:
			newRegion = CGRectMake(r.origin.x + dx, r.origin.y,
				r.size.width - dx, r.size.height);
			break;
		case LTDragModeRight:
			newRegion = CGRectMake(r.origin.x, r.origin.y,
				r.size.width + dx, r.size.height);
			break;
		default:
			break;
	}

	self.selectedRegion = newRegion;
	if (self.regionDidChangeBlock) {
		self.regionDidChangeBlock(self.selectedRegion);
	}
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	self.dragMode = LTDragModeNone;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	self.dragMode = LTDragModeNone;
}

@end
