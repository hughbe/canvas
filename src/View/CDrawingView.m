//
//  CDrawingView.m
//  canvas
//
//  Created by Hugh Bellamy on 09/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CDrawingView.h"
#import "UIExtensions.h"
#import "CModel.h"
#import <objc/runtime.h>

static char COLOR_KEY;
static char OPACITY_KEY;

static char BLEND_MODE_KEY;
static char TYPE_KEY;

static char SHAPE_KEY;

static char HIDDEN_BEFORE_KEY;
static char HIDDEN_KEY;

@interface CDrawingView ()
void MyCGPathApplierFunc (void *info, const CGPathElement *element);
@property (nonatomic, strong) UIImage *incrementalImage;

@property (nonatomic, assign) CGPoint firstPoint;
@property (nonatomic, assign) CGPoint controlPoint;

@property (nonatomic, assign, getter = isDoingSomething) BOOL doingSomething;

@property (nonatomic, strong) NSMutableArray *completeArray;

@end

@implementation CDrawingView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.completeArray = [NSMutableArray new];
    //Sets up our gesture recognizers for painting
    self.multipleTouchEnabled = NO;
    
    //Drag painting
    self.panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panned:)];
    self.panGesture.delegate = self;
    self.panGesture.minimumNumberOfTouches = 1;
    self.panGesture.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:self.panGesture];
    
    //Tap painting
    self.tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped:)];
    self.tapGesture.delegate = self;
    self.tapGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:self.tapGesture];
    
    //Creates our path holding variable
    self.pathArray = [NSMutableArray new];
    self.bufferArray = [NSMutableArray new];
    
    //Updates the stroke's settings
    self.brushType = CBrushTypeNormal;
    
    self.color = [UIColor brownColor];
    self.lineWidth = 30.0f;
    self.opacity = 1.0f;
    
    self.lineCap = kCGLineCapRound;
    self.brushPatternType = CBrushPatternNormal;
    self.blendMode = kCGBlendModeNormal;
}

- (void)setBrushType:(CBrushType)brushType {
    _brushType = brushType;
    
    if(brushType == CBrushTypeFill || brushType == CBrushTypeDelete) {
        self.panGesture.enabled = NO;
    }
    else {
        self.panGesture.enabled = YES;
    }
    
    if(brushType == CBrushTypeStraightLine || brushType == CBrushTypeMove) {
        self.tapGesture.enabled = NO;
    }
    else {
        self.tapGesture.enabled = YES;
    }
}

- (void)drawRect:(CGRect)rect {
    
    /*if(self.incrementalImage) {
        [self.incrementalImage drawInRect:rect];
    }*/
    
    //But are we erasing...
    if(self.path.color == [UIColor clearColor]) {
        //[[UIColor clearColor] setStroke];
        UIImageView *imageView = (UIImageView*)self.incrementalView.superview;
        if(imageView.image) {
            [[imageView.image patternColor]setStroke];
        }
        else {
            [self.incrementalView.superview.backgroundColor setStroke];
        }
        [self.path strokeWithBlendMode:kCGBlendModeCopy alpha:1.0f];
    }
    
    //Shapes are filled in
    else if(self.path.type == CBrushTypeShape) {
        [self.path.color setFill];
        [self.path fillWithBlendMode:self.path.blendMode alpha:self.path.opacity];
    }
    else {
        [self.path.color setStroke];
        [self.path strokeWithBlendMode:self.path.blendMode alpha:self.path.opacity];
    }
}

- (void)drawBitmap {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
        //Creates a copy of our current pathArray to prevent mutability crash
    for (UIBezierPath *currentPath in [self.pathArray copy]) {
        if(currentPath.isHiddenNow || currentPath == self.path) {
            continue;
        }
        //Loops through our paths and adds them to our view
        [currentPath.color setStroke];
        //But are we erasing...
        if(currentPath.color == [UIColor clearColor]) {
            UIImageView *imageView = (UIImageView*)self.incrementalView.superview;
            if(imageView.image) {
                [[imageView.image patternColor]setStroke];
            }
            else {
                [self.incrementalView.superview.backgroundColor setStroke];
            }

            //Yes, so clear everything
            [currentPath strokeWithBlendMode:kCGBlendModeCopy alpha:1.0f];
        }
        //Shapes are filled in
        else if(currentPath.type == CBrushTypeShape) {
            [currentPath.color setFill];
            [currentPath fillWithBlendMode:currentPath.blendMode alpha:currentPath.opacity];
        }
        else {
            [currentPath.color setStroke];
            [currentPath strokeWithBlendMode:currentPath.blendMode alpha:currentPath.opacity];
        }
    }
    self.incrementalView.image  = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self setNeedsDisplay];
}

BOOL movingLine;

- (void)panned:(UIPanGestureRecognizer*)panGestureRecognizer {
    //What stage of painting are we at
    __block CGPoint p = [panGestureRecognizer locationInView:self];
    if(panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        //We're starting, so resets our path
        [self setupPath];
        movingLine = NO;
        self.controlPoint = CGPointZero;
        
        if(self.brushType != CBrushTypeMove) {
            //Now, add the current point to the pathArray and display it
            [self.path moveToPoint:p];
            
            if(self.brushType == CBrushTypeStraightLine) {
                self.firstPoint = p;
                if([self.pathArray count] >= 1) {
                    [self getNearestStraightLineFromPoint:p withBlock:^(CGPoint point, UIBezierPath *path, CGPoint firstPoint) {
                        self.firstPoint = point;
                        [self.path moveToPoint:point];
                    }];
                }
                self.path.type = CBrushTypeStraightLine;
            }
            else if(self.brushType == CBrushTypeShape) {
                //Shapes are shapes and have fixed anchor points
                self.firstPoint = p;
                self.path.type = CBrushTypeShape;
                self.path.shape = CShapeMake(self.shape.type, self.shape.filled, self.shape.rounded);
            }
            else {
                //Our normal handling
                self.firstPoint = CGPointZero;
                
                self.path.type = self.brushType;
                [self.path addLineToPoint:p];
            }
            
            [self setNeedsDisplay];
        }
        else {
            [self setupPath];
            [self getNearestStraightLineFromPoint:p withBlock:^(CGPoint point, UIBezierPath *path, CGPoint firstPoint) {
                if(!CGPointEqualToPoint(point, CGPointZero)) {
                    movingLine = YES;
                    [self.pathArray removeObject:path];
                    self.firstPoint = firstPoint;
                    [self.path moveToPoint:self.firstPoint];
                    self.path = [path safeCopy];
                }
            }];
            
            if(self.path.isEmpty) {
                for (UIBezierPath *aPath in [[[self.pathArray reverseObjectEnumerator]allObjects] copy]) {
                    if(aPath.type == CBrushTypeEraser) {
                        continue;
                    }
                    UIBezierPath *path;
                    if(aPath.type == CBrushTypeShape) {
                        path = aPath;
                    }
                    else {
                        CGPathRef CGPath = CGPathCreateCopyByStrokingPath(aPath.CGPath, NULL, aPath.lineWidth, aPath.lineCapStyle, aPath.lineJoinStyle, aPath.miterLimit);
                        path = [UIBezierPath bezierPathWithCGPath:CGPath];
                        CGPathRelease(CGPath);
                    }
                    if([path containsPoint:p]) {
                        movingLine = NO;
                        self.path = [aPath safeCopy];
                        [self.pathArray removeObject:aPath];
                        self.firstPoint = p;
                        self.controlPoint = p;
                        break;
                    }
                }
            }
            
            [self drawBitmap];
        }
    }
    else if(panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if(self.path.isEmpty) {
            return;
        }
        
        GenericBlockType moveLineEnd = ^{
            //Straight lines can only have start and end (start is always fixed)
            [self.path removeAllPoints];
            [self.path moveToPoint:self.firstPoint];
            [self.path addLineToPoint:p];
        };
        
        GenericBlockType moveLine = ^{
           // p.x += self.path.bounds.size.width / 2;
           // p.y += self.path.bounds.size.height / 2;
            CGPathRef path = self.path.CGPath;
            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformIdentity, p.x - self.controlPoint.x, p.y - self.controlPoint.y);
            self.controlPoint = p;
            
            path = CGPathCreateMutableCopyByTransformingPath(path, &transform);
            self.path.CGPath = path;
            CGPathRelease(path);
        };
        
        GenericBlockType sizeShape = ^{
            //FIXME
            /*CGRect frame = CGRectMake(0, 0, MAX(self.firstPoint.x, p.x) - MIN(self.firstPoint.x, p.x), MAX(self.firstPoint.y, p.y) - MIN(self.firstPoint.y, p.y));
            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformIdentity, MIN(self.firstPoint.x, p.x), MIN(self.firstPoint.y, p.y));
            UIBezierPath *bezierPath = [UIBezierPath bezierPathFromShapeID:self.path.shape.type frame:frame filled:self.path.shape.filled rounded:self.path.shape.rounded];
            
            //Move the path up or down to suit the position of our touch
            CGPathRef path = bezierPath.CGPath;
            
            path = CGPathCreateMutableCopyByTransformingPath(path, &transform);
            self.path.CGPath = path;
            CGPathRelease(path);
             */
        };
        
        GenericBlockType moveShape = ^{
            CGPathRef path = self.path.CGPath;
            CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformIdentity, p.x - self.controlPoint.x, p.y - self.controlPoint.y);
            self.controlPoint = p;
            
            path = CGPathCreateMutableCopyByTransformingPath(path, &transform);
            self.path.CGPath = path;
            CGPathRelease(path);
        };
        
        if(self.brushType == CBrushTypeMove) {
            if(self.path.type == CBrushTypeStraightLine) {
                if(movingLine) {
                    //We're moving a line end
                    moveLineEnd();
                }
                else {
                    //We're moving a whole line
                    moveLine();
                }
            }
            else if(self.path.type == CBrushTypeNormal) {
                moveLine();
            }
            else if(self.path.type == CBrushTypeShape) {
                moveShape();
            }
        }
        else if(self.brushType == CBrushTypeStraightLine) {
            //Moves our line's end
            moveLineEnd();
        }
        else if(self.brushType == CBrushTypeShape) {
            //Moves our shape
            sizeShape();
        }
        else if(self.brushType == CBrushTypeNormal || self.brushType == CBrushTypeEraser) {
            //We're moving to a new point, so add it to our path and refresh the display of it
            [self.path addLineToPoint:p];
        }
        
        [self setNeedsDisplay];
    }
    else if(panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled || panGestureRecognizer.state == UIGestureRecognizerStateFailed) {
        if(self.path.isEmpty) {
            return;
        }
        //If we're connecting lines together
        if(self.brushType == CBrushTypeStraightLine || self.brushType == CBrushTypeMove) {
            [self getNearestStraightLineFromPoint:p withBlock:^(CGPoint point, UIBezierPath *path, CGPoint firstPoint) {
                [self.path removeAllPoints];
                [self.path moveToPoint:self.firstPoint];
                [self.path addLineToPoint:point];
                //[self setNeedsDisplay];
            }];
        }
        
        self.firstPoint = p;
        
        //Updates our undo and redo buttons
        self.canUndo = YES;
        [self.delegate updateUndoRedo];
        
        [self.pathArray addObject:[self.path safeCopy]];
        self.path = nil;
        
        [self.completeArray addObject:[self.pathArray mutableCopy]];
        
        [self drawBitmap];
    }
}

- (void)tapped:(UITapGestureRecognizer*)tapGestureRecognizer {
    CGPoint p = [tapGestureRecognizer locationInView:self];
    if(self.brushType == CBrushTypeEraser || self.brushType == CBrushTypeNormal) {
        //Resets our path
        [self setupPath];
        
        //Now, add the current point to the pathArray and display i
        [self.path moveToPoint:p];
        [self.path addLineToPoint:p];
        self.path.type = self.brushType;
        
        [self.pathArray addObject:[self.path safeCopy]];
        self.path = nil;
        
        self.canUndo = YES;
        [self.delegate updateUndoRedo];
    }
    else if(self.brushType == CBrushTypeFill || self.brushType == CBrushTypeDelete) {
        if(!self.isDoingSomething) {
            self.doingSomething = YES;
            for (UIBezierPath *aPath in [[self.pathArray reverseObjectEnumerator]allObjects]) {
                UIBezierPath *path;
                if(aPath.type == CBrushTypeShape) {
                    path = aPath;
                }
                else {
                    path = [UIBezierPath bezierPathWithCGPath:CGPathCreateCopyByStrokingPath(aPath.CGPath, NULL, aPath.lineWidth, aPath.lineCapStyle, aPath.lineJoinStyle, aPath.miterLimit)];
                }
                
                if([path containsPoint:p]) {
                    if(self.brushType == CBrushTypeFill) {
                        [self.pathArray removeObject:aPath];
                        
                        self.path = [UIBezierPath bezierPathWithCGPath:aPath.CGPath];
                        
                        self.path.lineJoinStyle = aPath.lineJoinStyle;
                        self.path.lineCapStyle = aPath.lineCapStyle;
                        self.path.miterLimit = aPath.miterLimit;
                        
                        self.path.color = self.color;
                        self.path.lineWidth = aPath.lineWidth + 1;
                        self.path.type = aPath.type;
                        self.path.opacity = aPath.opacity;
                        self.path.hiddenInfo = CHiddenInfoMake(NO, 0);
                        
                        [self.pathArray addObject:[self.path safeCopy]];
                        self.path = nil;
                    }
                    else {
                        //Delete the path
                        //aPath.hidden = YES;
                        //aPath.hiddenInfo = CHiddenInfoMake(YES, [self.pathArray count]);
                        [self.pathArray removeObject:aPath];
                    }
                    
                    break;
                }
            }
            
            self.doingSomething = NO;
            if([self.pathArray count] > 0) {
                self.canUndo = YES;
            }
            else {
                self.canUndo = NO;
            }
            [self.delegate updateUndoRedo];
        }
    }
    
    [self.completeArray addObject:[self.pathArray mutableCopy]];
    [self drawBitmap];
}

- (void)getNearestStraightLineFromPoint:(CGPoint)point withBlock:(void(^)(CGPoint point, UIBezierPath *ownerPath, CGPoint firstPoint))block {
    NSMutableArray *points = [NSMutableArray new];
    for (UIBezierPath *path in [[[self.pathArray reverseObjectEnumerator]allObjects] copy]) {
        if(path.type == CBrushTypeShape || path.type == CBrushTypeNormal || path == self.path || path.isHiddenNow) {
            continue;
        }
        
        //Loop through our visible paths and get an array of all of them
        NSMutableArray *bezierPathPoints = [NSMutableArray array];
        CGPathApply(path.CGPath, (__bridge void *)(bezierPathPoints), MyCGPathApplierFunc);
        
        //Makes sure we have points
        if([bezierPathPoints count] > 0) {
            //Gets the start and end of the path
            CGPoint start = [[bezierPathPoints firstObject] CGPointValue];
            CGPoint end = [[bezierPathPoints lastObject]CGPointValue];
            
            //If we're close enough to the start of end of a line, snap onto it!
            CGFloat distanceFromStart = CGPointDistanceFromPoint(point, start);
            CGFloat distanceFromEnd = CGPointDistanceFromPoint(point, end);
            
            if (distanceFromStart < 30 && [self.pathArray count] > 0) {
                [points addObject:@[NSStringFromCGPoint(start), @(distanceFromStart), path, NSStringFromCGPoint(end)]];
            }
            else if (distanceFromEnd < 30 && [self.pathArray count] > 0) {
                [points addObject:@[NSStringFromCGPoint(end), @(distanceFromEnd), path, NSStringFromCGPoint(start)]];
            }
        }
    }
    
    NSArray *sortedPoints = [points sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *firstDistance = obj1[1];
        NSNumber *secondDistance = obj2[1];
        return [firstDistance compare:secondDistance];
    }];
    
    if([sortedPoints count]> 0) {
        NSInteger index = 0;
        if ([sortedPoints count] > 1) {
            index = 1;
        }
        
        block(CGPointFromString([[sortedPoints objectAtIndex:index]firstObject]), [[sortedPoints objectAtIndex:index]objectAtIndex:2], CGPointFromString([[sortedPoints objectAtIndex:index]objectAtIndex:3]));
    }
}

void MyCGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
        case kCGPathElementMoveToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[2]]];
            break;
        case kCGPathElementCloseSubpath: // contains no point
            break;
    }
}

- (void)setupPath {
    //Remove all points and updates the necessary variables for our path
    self.path = [UIBezierPath bezierPath];
    [self setupPathVariables];
}

- (void)setupPathWithCGPath:(CGPathRef)path {
    //Remove all points and updates the necessary variables for our path
    self.path = [UIBezierPath bezierPathWithCGPath:path];
    [self setupPathVariables];
}

- (void)setupPathVariables {
    //Sets up the path's variables
    self.path.color = self.color;
    self.path.lineWidth = self.lineWidth;
    self.path.opacity = self.opacity;
    
    self.path.hiddenInfo = CHiddenInfoMake(NO, 0);
    self.path.type = CBrushTypeNormal;
    self.path.shape = CShapeMake(0, NO, NO);
    
    self.path.lineCapStyle = self.lineCap;
    self.path.blendMode = self.blendMode;
    
    if(self.path.lineCapStyle != kCGLineCapRound) {
        self.path.miterLimit = 10;
        self.path.lineJoinStyle = kCGLineJoinBevel;
    }
    else {
        self.path.lineJoinStyle = kCGLineJoinRound;
        self.path.miterLimit = -10;
    }
    
    if(self.brushPatternType == CBrushPatternDashed1 || self.brushPatternType == CBrushPatternDashed2 || self.brushPatternType == CBrushPatternDashed3 || self.brushPatternType == CBrushPatternDashed4) {
        //Sets up our dashed line
        CGFloat dashes[2];
        NSInteger count = 1;
        switch (self.brushPatternType) {
            case CBrushPatternDashed1:
                //Continuous (sausages)
                dashes[0] = self.lineWidth;
                break;
            case CBrushPatternDashed2:
                //Split apart (e.g footsteps)
                dashes[0] = self.lineWidth * 1.5;
                break;
            case CBrushPatternDashed3:
                dashes[0] = self.lineWidth * 2;
                break;
            case CBrushPatternDashed4:
                count = 2;
                dashes[0] = self.lineWidth;
                dashes[1] = self.lineWidth * 4;
                break;
            default:
                break;
        }
        
        [self.path setLineDash:dashes count:count phase:dashes[0]];
    }
    else if(self.brushPatternType != CBrushPatternNormal && self.brushType != CBrushTypeEraser) {
        NSString *fileName = [CModel fileNameForBrushPatternType:self.brushPatternType];
        self.path.color = [[UIImage imageNamed:fileName]patternColor];
    }
}

- (void)undo {
    if([self.pathArray count] > 0) {
        //Gets what we're removing from our stack and putting onto the redo stack
        UIBezierPath *currentPath = [self.pathArray lastObject];
        //Index of HiddenInfo shows when we removed the line from display
        if(currentPath.isHiddenNow) {
            currentPath.hidden = NO;
        }
        else {
            [self.pathArray removeLastObject];
        }
        
        [self.bufferArray addObject:currentPath];
        [self drawBitmap];
        //Checks if we can undo again
        if([self.pathArray count] == 0) {
            self.canUndo = NO;
        }
        else {
            self.canUndo = YES;
        }
        self.canRedo = YES;
    }
    else {
        self.canUndo = NO;
    }
    //Updates our undo and redo buttons
    [self.delegate updateUndoRedo];
}

- (void)redo {
    
    //Checks if there is anything to redo
    if([self.bufferArray count] > 0) {
        //Gets what we're putting back onto our stack
        UIBezierPath *currentPath = [self.bufferArray lastObject];
        //Index - the point at which we deleted / hid this path.
        //So if we are redoing something and the path has been removed at this point, then it should be hidden
        if(currentPath.hiddenInfo.hiddenBefore && currentPath.hiddenInfo.index == [self.pathArray count]) {
            currentPath.hidden = YES;
        }
        else {
            currentPath.hidden = NO;
        }
        
        [self.pathArray addObject:currentPath];
        [self.bufferArray removeLastObject];
        [self drawBitmap];
        
        //Checks if we can redo again
        if([self.bufferArray count] == 0) {
            self.canRedo = NO;
        }
        else {
            self.canRedo = YES;
        }
        self.canUndo = YES;
    }
    
    else {
        self.canRedo = NO;
    }
    //Updates our undo and redo buttons
    [self.delegate updateUndoRedo];
}

- (void)eraseAll {
    //Resets our undo and redo stacks
    [self.pathArray removeAllObjects];
    [self.bufferArray removeAllObjects];
    
    //Resets our current path and refreshes our view
    [self.path removeAllPoints];
    [self drawBitmap];
    
    //We no longer undo or redo
    self.canRedo = NO;
    self.canUndo = NO;
    [self.delegate updateUndoRedo];
}

- (UIImage *)renderImageWithContainer:(UIScrollView*)container opaque:(BOOL)opaque {
    UIImage* viewImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(container.contentSize, opaque, 0.0);
    {
        CGFloat borderWidth = self.layer.borderWidth;
        self.layer.borderWidth = 0.0;
        CGPoint savedContentOffset = container.contentOffset;
        CGRect savedFrame = container.frame;
        
        container.contentOffset = CGPointZero;
        container.frame = CGRectMake(0, 0, container.contentSize.width, container.contentSize.height);
        
        [container.layer renderInContext:UIGraphicsGetCurrentContext()];
        viewImage = UIGraphicsGetImageFromCurrentImageContext();
        
        container.contentOffset = savedContentOffset;
        container.frame = savedFrame;
        self.layer.borderWidth = borderWidth;
    }
    UIGraphicsEndImageContext();
    return viewImage;
}

@end

@implementation UIBezierPath(BezierPath)
/*
+ (void)load {
    // Swizzle UIColor encodeWithCoder:
    //Method encodeWithCoderAssociatedObject = class_getInstanceMethod([self class], @selector(encodeWithCoderAssociatedObject:));
    //Method encodeWithCoder = class_getInstanceMethod([self class], @selector(encodeWithCoder:));
   // method_exchangeImplementations(encodeWithCoder, encodeWithCoderAssociatedObject);
    
    // Swizzle UIColor initWithCoder:
    //Method initWithCoderAssociatedObject = class_getInstanceMethod([self class], @selector(initWithCoderAssociatedObject:));
    //Method initWithCoder = class_getInstanceMethod([self class], @selector(initWithCoder:));
    //method_exchangeImplementations(initWithCoder, initWithCoderAssociatedObject);
}

- (void)encodeWithCoderAssociatedObject:(NSCoder *)aCoder
{
    UIColor *color = self.color;
    CGFloat opacity = self.opacity;
    
    CBrushType type = self.type;
    CShape shape = self.shape;
    
    CGBlendMode blendMode = self.blendMode;
    
    CHiddenInfo hiddenInfo = self.hiddenInfo;
    BOOL hidden = self.isHiddenNow;
    
    [aCoder encodeObject:color forKey:@"color"];
    [aCoder encodeObject:@(opacity) forKey:@"opacity"];
    
    [aCoder encodeObject:@(type) forKey:@"type"];
    [aCoder encodeObject:[NSData dataWithBytes:&shape length:sizeof(CShape)] forKey:@"shape"];
    
    [aCoder encodeObject:@(blendMode) forKey:@"blendMode"];
    
    [aCoder encodeObject:[NSData dataWithBytes:&hiddenInfo length:sizeof(CHiddenInfo)] forKey:@"hiddenInfo"];
    [aCoder encodeObject:@(hidden) forKey:@"hidden"];
    
    [aCoder encodeObject:self forKey:@"path"];
}

- (id)initWithCoderAssociatedObject:(NSCoder *)aDecoder {
    if([aDecoder containsValueForKey:@"color"]) {
        if(self) {
            self.color = [aDecoder decodeObjectForKey:@"color"];
            self.opacity = [[aDecoder decodeObjectForKey:@"opacity"] floatValue];
            
            self.type = [[aDecoder decodeObjectForKey:@"type"] integerValue];
            
            CShape shape;
            [[aDecoder decodeObjectForKey:@"shape"]getBytes:&shape length:sizeof(CShape)];
            self.shape = shape;
            
            self.blendMode = [[aDecoder decodeObjectForKey:@"blendMode"]integerValue];
            
            CHiddenInfo hiddenInfo;
            [[aDecoder decodeObjectForKey:@"hiddenInfo"]getBytes:&hiddenInfo length:sizeof(CHiddenInfo)];
            self.hiddenInfo = hiddenInfo;
            self.hidden = [[aDecoder decodeObjectForKey:@"hidden"] boolValue];
        }
        return self;
    }
    else {
        // Call default implementation, Swizzled
        return [self initWithCoderAssociatedObject:aDecoder];
    }
}*/

- (UIBezierPath*)safeCopy {
    UIBezierPath *path = [self copy];
    path.color = self.color;
    path.lineWidth = self.lineWidth;
    path.opacity = self.opacity;
    
    path.blendMode = self.blendMode;
    path.type = self.type;
    path.shape = self.shape;
    
    path.hidden = self.hidden;
    path.hiddenInfo = self.hiddenInfo;
    
    return path;
}

- (void)setColor:(UIColor *)color {
    //Sets the associated color
    
    objc_setAssociatedObject(self, &COLOR_KEY, color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor*)color {
    //Gets the associated color
    return objc_getAssociatedObject(self, &COLOR_KEY);
}

- (void)setOpacity:(CGFloat)opacity {
    //Sets the associated opacity
    objc_setAssociatedObject(self, &OPACITY_KEY, @(opacity), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)opacity {
    //Gets the associated opacity
    return [objc_getAssociatedObject(self, &OPACITY_KEY) floatValue];
}

- (void)setBlendMode:(CGBlendMode)blendMode {
    //Sets the associated blendMode
    objc_setAssociatedObject(self, &BLEND_MODE_KEY, @(blendMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGBlendMode)blendMode {
    return (CGBlendMode)[objc_getAssociatedObject(self, &BLEND_MODE_KEY) integerValue];
}

- (void)setType:(CBrushType)type {
    //Sets the associated opacity
    objc_setAssociatedObject(self, &TYPE_KEY, @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CBrushType)type {
    //Gets the associated opacity
    return [objc_getAssociatedObject(self, &TYPE_KEY) integerValue];
}

- (void)setShape:(CShape)shape {
    //Sets the associated shape info
    objc_setAssociatedObject(self, &SHAPE_KEY, [NSValue valueWithBytes:&shape objCType:@encode(CShape)], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CShape)shape {
    //Gets the associated shape info
    CShape shape;
    [objc_getAssociatedObject(self, &SHAPE_KEY) getValue:&shape];
    return shape;
}

- (void)setHidden:(BOOL)hidden {
    //Sets the associated opacity
    objc_setAssociatedObject(self, &HIDDEN_KEY, @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isHiddenNow {
    //Gets the associated opacity
    return [objc_getAssociatedObject(self, &HIDDEN_KEY) boolValue];
}

- (void)setHiddenInfo:(CHiddenInfo)hiddenInfo {
    //Sets the associated opacity
    objc_setAssociatedObject(self, &HIDDEN_BEFORE_KEY, [NSValue valueWithBytes:&hiddenInfo objCType:@encode(CHiddenInfo)], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CHiddenInfo)hiddenInfo {
    //Gets the associated opacity
    CHiddenInfo hiddenInfo;
    [objc_getAssociatedObject(self, &HIDDEN_BEFORE_KEY) getValue:&hiddenInfo];
    return hiddenInfo;
}

@end
