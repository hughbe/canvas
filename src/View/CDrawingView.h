//
//  CDrawingView.h
//  canvas
//
//  Created by Hugh Bellamy on 09/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CDrawViewDelegate<NSObject>

-(void)updateUndoRedo;

@end

typedef NS_ENUM(NSInteger, CBrushType) {
    CBrushTypeEraser,
    CBrushTypeNormal,
    CBrushTypeStraightLine,
    CBrushTypeShape,
    CBrushTypeFill,
    CBrushTypeMove,
    CBrushTypeDelete
};

typedef NS_ENUM(NSInteger, CBrushPatternType) {
    CBrushPatternNormal,
    CBrushPatternDashed1,
    CBrushPatternDashed2,
    CBrushPatternDashed3,
    CBrushPatternDashed4,
    CBrushPatternWood1,
    CBrushPatternWood2,
    CBrushPatternWood3,
    CBrushPatternWood4,
    CBrushPatternAsphalt,
    CBrushPatternConcrete1,
    CBrushPatternConcrete2,
    CBrushPatternLeather1,
    CBrushPatternLeather2,
    CBrushPatternLeather3,
    CBrushPatternFur,
    CBrushPatternCarpet1,
    CBrushPatternCarpet2,
    CBrushPatternBrick1,
    CBrushPatternBrick2,
    CBrushPatternBrick3,
    CBrushPatternPath1,
    CBrushPatternPath2,
    CBrushPatternRoof1,
    CBrushPatternRoof2,
    CBrushPatternRoof3,
    CBrushPatternStone1,
    CBrushPatternStone2,
    CBrushPatternStone3,
    CBrushPatternRock1,
    CBrushPatternRock2,
    CBrushPatternMarble1,
    CBrushPatternMarble2,
    CBrushPatternMetal1,
    CBrushPatternMetal2,
    CBrushPatternMetal3,
    CBrushPatternGrass1,
    CBrushPatternGrass2,
    CBrushPatternHay,
    CBrushPatternMud1,
    CBrushPatternMud2,
    CBrushPatternMud3,
    CBrushPatternSand1,
    CBrushPatternSand2,
    CBrushPatternSky1,
    CBrushPatternSky2,
    CBrushPatternSky3,
    CBrushPatternWater1,
    CBrushPatternWater2,
    CBrushPatternWater3,
    CBrushPatternSnow,
    CBrushPatternIce,
    CBrushPatternLava,
    CBrushPatternPaper,
    CBrushPatternCardboard
};

typedef NS_ENUM(NSInteger, CShapeType) {
    CShapeCircle,
    CShapeTriangle,
    CShapeSquare,
    CShapeRectangle,
    CShapeRhombus,
    CShapeKite,
    CShapePentagon,
    CShapeHexagon,
    CShapeHeptagon,
    CShapeParallelLines,
    CShapeSmileyHappyCircular,
    CSHapeSmileyDisturbed,
    CShapeSmileyNeutralCircular,
    CShapeSmileyAwkwardCircular,
    CShapeSmileySadCircular,
    CShapeSmileyHappy,
    CShapeSmileyNeutral,
    CShapeSmileyAwkward,
    CShapeSmileySad,
    CShapeA,
    CShapeB,
    CShapeC,
    CShapeD,
    CShapeE,
    CShapeF,
    CShapeG,
    CShapeH,
    CShapeI,
    CShapeJ,
    CShapeK,
    CShapeL,
    CShapeM,
    CShapeN,
    CShapeO,
    CShapeP,
    CShapeQ,
    CShapeR,
    CShapeS,
    CShapeT,
    CShapeU,
    CShapeV,
    CShapeW,
    CShapeX,
    CShapeY,
    CShapeZ
};

struct CShape {
    NSInteger type;
    BOOL filled;
    BOOL rounded;
};
typedef struct CShape CShape;

struct CHiddenInfo {
    BOOL hiddenBefore;
    NSUInteger index;
};
typedef struct CHiddenInfo CHiddenInfo;

static inline CShape CShapeMake(NSInteger shapeType, BOOL filled, BOOL rounded) {
    CShape shape;
    shape.type = shapeType;
    shape.filled = filled;
    shape.rounded = rounded;
    return shape;
};

static inline CHiddenInfo CHiddenInfoMake(BOOL hiddenBefore, NSInteger index) {
    CHiddenInfo hiddenInfo;
    hiddenInfo.hiddenBefore = hiddenBefore;
    hiddenInfo.index = index;
    return hiddenInfo;
};

@interface CDrawingView : UIView<UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGFloat opacity;

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *backupColor;

@property (nonatomic, assign) CGLineCap lineCap;

@property (nonatomic, weak) id<CDrawViewDelegate> delegate;

@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) NSMutableArray *pathArray;
@property (nonatomic, strong) NSMutableArray *bufferArray;

@property (nonatomic, strong) UIImageView *incrementalView;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, assign) BOOL canUndo;
@property (nonatomic, assign) BOOL canRedo;

@property (nonatomic, assign) CBrushType brushType;
@property (nonatomic, assign) CBrushPatternType brushPatternType;

@property (nonatomic, assign) CGBlendMode blendMode;

@property (nonatomic, assign) CShape shape;

- (void)drawBitmap;

- (void)undo;
- (void)redo;

- (void)eraseAll;

- (UIImage *)renderImageWithContainer:(UIScrollView*)container opaque:(BOOL)opaque;

@end

@interface UIBezierPath(BezierPath)

- (UIBezierPath*)safeCopy;

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat opacity;

@property (nonatomic, assign) CBrushType type;

@property (nonatomic, assign) CGBlendMode blendMode;

@property (nonatomic, assign) CHiddenInfo hiddenInfo;
@property (nonatomic, assign, getter = isHiddenNow) BOOL hidden;

@property (nonatomic, assign) CShape shape;

@end

