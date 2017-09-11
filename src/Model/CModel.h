//
//  CModel.h
//  canvas
//
//  Created by Hugh Bellamy on 09/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIExtensions.h"
#import "CDrawingView.h"

#define LINE_CAP_CHANGED_NOTIFICATION_NAME @"LCCN"

@interface NSArray (CModelSerialisation)

- (NSData*)serialize;
- (NSArray *)deserialize;

@end

@interface CModel : NSObject

@property (strong, nonatomic) NSMutableArray *source;

- (void)addDrawing:(UIImage*)drawing withTitle:(NSString*)title background:(id)background  size:(CGSize)size pathArray:(NSArray*)pathArray videoPath:videoPath completion:(GenericBlockType)completion;
- (void)updateDrawing:(NSString*)ID drawing:(UIImage*)drawing title:(NSString*)title background:(id)background size:(CGSize)size pathArray:(NSArray*)pathArray videoPath:videoPath completion:(GenericBlockType)completion;
- (void)removeDrawingWithID:(NSString *)ID completion:(GenericBlockType)completion;

- (void)loadSource;
- (NSNumber*)getNewID;

+ (NSArray*)tips;
+ (NSArray*)shapeTitles;

+ (NSArray*)brushPatternTitles;
+ (NSString*)fileNameForBrushPatternType:(CBrushPatternType)type;

+ (NSArray*)blendModeTitles;
+ (CGBlendMode)blendModeForTitle:(NSString*)title;

+ (NSString*)documentPathForFileName:(NSString*)fileName;
+ (NSString*)documentPathForPNGFileName:(NSString*)fileName;

+ (void)setupFirstUse:(UIColor*)backgroundColor;

+ (void)writeStrokeColor:(UIColor*)color;
+ (UIColor*)strokeColor;

+ (void)writeLineWidth:(float)lineWidth;
+ (float)lineWidth;

+ (void)writeOpacity:(float)opacity;
+ (float)opacity;

+ (void)writeLineCapStyle:(CGLineCap)lineCap;
+ (CGLineCap)lineCapStyle;

+ (void)writeBrushPatternType:(CBrushPatternType)brushPatternType;
+ (CBrushPatternType)brushPatternType;

+ (void)writeBrushBlendMode:(NSString*)brushBlendMode;
+ (NSString*)brushBlendMode;

+ (void)writeBackgroundColor:(UIColor*)color;
+ (UIColor*)backgroundColor;

+ (UIColor*)defaultBackgroundColor;

+ (void)writeSizeWidth:(float)width;
+ (float)sizeWidth;

+ (void)writeSizeHeight:(float)height;
+ (float)sizeHeight;

+ (void)writeCanUseMoreBrushes:(BOOL)canUseMoreBrushes;
+ (BOOL)canUseMoreBrushes;
@end
