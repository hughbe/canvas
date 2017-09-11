//
//  CShapeCell.m
//  canvas
//
//  Created by Hugh Bellamy on 17/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CShapeCell.h"
#import "UIExtensions.h"

@implementation CShapeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    //Sets up the shapeCell's display
    self.layer.cornerRadius = 5.0f;
    self.layer.borderWidth = 1.0f;
    
    //Adds a shadow to our topView
    self.titleLabel.superview.clipsToBounds = NO;
    self.titleLabel.superview.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.titleLabel.superview.layer.shadowOffset = CGSizeMake(0.0f,10.0f);
    self.titleLabel.superview.layer.shadowOpacity = .5f;
    self.titleLabel.superview.layer.shadowRadius = 10.0f;
    
    [self.titleLabel.superview addBottomBorderWithWidth:2.0 color:[UIColor darkGrayColor]];
}

@end
