// LTEditorManager.h
// Lightweight image annotation/edit module used after a screenshot or
// long-shot capture: crop, add text labels, and draw freehand marks
// via a UIGraphicsImageRenderer-based compositor.
//
// Extension point: LTEditorOperation is an append-only ledger of edits
// so undo/redo and future operation types (arrow, blur, mosaic) can be
// added without changing the rendering entry point -renderFinalImage.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LTManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LTEditorOperationType) {
	LTEditorOperationCrop = 0,
	LTEditorOperationText,
	LTEditorOperationStroke,
};

@interface LTEditorOperation : NSObject
@property (nonatomic, assign) LTEditorOperationType type;
@property (nonatomic, assign) CGRect rect;          // crop rect / text box
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, strong, nullable) UIBezierPath *path; // freehand stroke
@end

@interface LTEditorManager : NSObject <LTModule>

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) NSMutableArray<LTEditorOperation *> *operations;
@property (nonatomic, strong, nullable) UIImage *baseImage;

- (void)beginEditingImage:(UIImage *)image;
- (void)addOperation:(LTEditorOperation *)operation;
- (void)undoLastOperation;
- (void)clearOperations;

// Composites baseImage + all operations into a final flattened image.
- (nullable UIImage *)renderFinalImage;

@end

NS_ASSUME_NONNULL_END
