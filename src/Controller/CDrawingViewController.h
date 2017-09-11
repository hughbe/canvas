//
//  CViewController.h
//  canvas
//
//  Created by Hugh Bellamy on 09/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CDrawingView.h"
@class CBrushView;
@class CDrawingToolbar;

#import "ChooseColorViewController.h"
#import "CChooseBrushViewController.h"
#import "CChooseShapeViewController.h"

#import "CSizeViewController.h"

@protocol CDrawViewControllerDelegate<NSObject>

- (void)drawingWasChosen:(UIImage *)drawing title:(NSString*)title background:(id)background size:(CGSize)size pathArray:(NSArray *)pathArray ID:(NSString *)ID videoPath:(NSString *)videoPath;

@end

@interface CDrawingViewController : UIViewController<CDrawViewDelegate, ChooseColorDelegate, CChooseShapeDelegate, CChooseSizeDelegate, CChooseBrushDelegate, CChooseBlendModeDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) id<CDrawViewControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIScrollView *containerView;
@property (nonatomic, weak) IBOutlet UIImageView *drawingBackgroundView;
@property (nonatomic, weak) IBOutlet CDrawingView *drawingView;
@property (weak, nonatomic) IBOutlet UIImageView *drawingIncrementalView;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *showHideDrawingToolbarButton;

@property (nonatomic, weak) IBOutlet UIToolbar *drawingToolbar;
@property (nonatomic, weak) IBOutlet UIToolbar *opacityLineWidthToolbar;

@property (nonatomic, weak) IBOutlet UIToolbar *shapeBackgroundToolbar;
@property (nonatomic, weak) IBOutlet UIButton *shapeBackgroundButton;

@property (nonatomic, weak) IBOutlet UISlider *opacityLineWidthSlider;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *opacityLineWidthLabel;

@property (nonatomic, weak) IBOutlet UIButton *lineWidthButton;
@property (nonatomic, weak) IBOutlet UIButton*opacityButton;
@property (weak, nonatomic) IBOutlet UIButton *brushTypeButton;

@property (nonatomic, weak) IBOutlet UIButton *undoButton;
@property (nonatomic, weak) IBOutlet UIButton *redoButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sizeBarButton;

@property (nonatomic, weak) IBOutlet CBrushView *brushView;

@property (nonatomic, strong) NSString *ID;

@property (nonatomic, strong) NSNumber *videoID;
@property (nonatomic, strong) NSString *videoPath;

@property (nonatomic, assign) float width;
@property (nonatomic, assign) float height;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIColor *backgroundColor;

@property (nonatomic, strong) NSArray *pathArray;

@property (nonatomic, strong) NSString *drawingTitle;

@end
