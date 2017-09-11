//
//  CBrushView.h
//  canvas
//
//  Created by Hugh Bellamy on 23/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CBrushView : UIView

@property (weak, nonatomic) IBOutlet UIButton *eraseButton;
@property (weak, nonatomic) IBOutlet UIButton *normalButton;
@property (weak, nonatomic) IBOutlet UIButton *lineButton;
@property (weak, nonatomic) IBOutlet UIButton *shapeButton;
@property (weak, nonatomic) IBOutlet UIButton *fillButton;
@end
