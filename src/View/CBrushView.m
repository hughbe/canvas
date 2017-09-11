//
//  CBrushView.m
//  canvas
//
//  Created by Hugh Bellamy on 23/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CBrushView.h"

#import "UIImage+Additions.h"

@implementation CBrushView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layer.borderWidth = 2.0;
    self.layer.cornerRadius = 10.0;
    
    UIImage *tintedImage = [self.normalButton.currentBackgroundImage add_tintedImageWithColor:[UIColor redColor] style:ADDImageTintStyleOverAlpha];
    [self.normalButton setBackgroundImage:tintedImage forState:UIControlStateNormal];
}

@end
