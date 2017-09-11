//
//  CBrushTypeReusableView.m
//  canvas
//
//  Created by Hugh Bellamy on 04/01/2014.
//  Copyright (c) 2014 Hugh Bellamy. All rights reserved.
//

#import "CBrushTypeReusableView.h"
#import "CModel.h"

@implementation CBrushTypeReusableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)lineCapChanged:(UISegmentedControl*)sender {
    if(sender.selectedSegmentIndex == 0) {
        //Rounded
        [CModel writeLineCapStyle:kCGLineCapRound];
    }
    else {
        //Square
        [CModel writeLineCapStyle:kCGLineCapSquare];
    }
    //Tell the drawingView that we changed the lineCap
    [[NSNotificationCenter defaultCenter]postNotificationName:LINE_CAP_CHANGED_NOTIFICATION_NAME object:@([CModel lineCapStyle])];
}

@end
