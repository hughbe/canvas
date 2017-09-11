//
//  CBrushView.m
//  canvas
//
//  Created by Hugh Bellamy on 23/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CBrushView.h"
#import "UIExtensions.h"

@implementation CBrushView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layer.borderWidth = 2.0;
    self.layer.cornerRadius = 10.0;
    [self.normalButton tintBackgroundImageWithColor:[UIColor redColor]];
}

@end
