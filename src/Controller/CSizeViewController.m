//
//  CSizeViewController.m
//  canvas
//
//  Created by Hugh Bellamy on 13/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CSizeViewController.h"

#import "CModel.h"
#import "UIImage+Additions.h"

@interface CSizeViewController ()

- (void)updateSliderValues;

@property (nonatomic, assign) float aspectRatio;

@end

@implementation CSizeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Gets our width and height
    float width = [CModel sizeWidth];
    float height = [CModel sizeHeight];
    
    CGSize minSize = [UIScreen mainScreen].bounds.size;
    minSize.height -= self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    //Makes sure that we always have a value
    if(width == 0) {
        width = minSize.width;
    }
    if(height == 0) {
        height = minSize.height;
    }
    
    self.widthSlider.minimumValue = minSize.width;
    self.heightSlider.minimumValue = minSize.height;
    
    
    [self defineMaxSize:width height:height];
    
    self.widthSlider.value = width;
    self.heightSlider.value = height;
    [self sliderChanged:self.widthSlider];
    [self sliderChanged:self.heightSlider];
    
    UIButton *button = self.navigationItem.rightBarButtonItem.customView;
    UIImage *tintedImage = [button.currentBackgroundImage add_tintedImageWithColor:[UIColor whiteColor] style:ADDImageTintStyleOverAlpha];
    [button setBackgroundImage:tintedImage forState:UIControlStateNormal];
}

- (IBAction)sliderChanged:(UISlider*)sender {
    if(sender == self.widthSlider) {
        //Updates our width
        self.heightSlider.value = sender.value * self.aspectRatio;
    }
    else {
        //Updates our height
        self.widthSlider.value = sender.value / self.aspectRatio;
    }
    [self updateSliderValues];
}

- (void)updateSliderValues {
    //Formats our sliders to visible text
    self.widthlabel.text = [NSString stringWithFormat:@"%.f", self.widthSlider.value];
    self.heightLabel.text = [NSString stringWithFormat:@"%.f", self.heightSlider.value];
}

- (void)defineMaxSize:(float)width height:(float)height {
    //Defines an aspect ratio for our view
    self.widthSlider.maximumValue = 1000;
    if(height > width) {
        self.aspectRatio = height / width;
        self.heightSlider.maximumValue = 1000 * self.aspectRatio;
    }
    else {
        self.aspectRatio = width / height;
        self.heightSlider.maximumValue = 1000 / self.aspectRatio;
    }
}

- (IBAction)reset:(id)sender {
    CGSize size;
    if(CGSizeEqualToSize(self.resetSize, CGSizeZero)) {
        //Reset to default size
        size = [UIScreen mainScreen].bounds.size;
        size.height -= self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    else {
        //Reset to specified size
        size = self.resetSize;
    }
    
    //Defines an aspect ratio for our view
    [self defineMaxSize:size.width height:size.height];
    
    //And update our UI and model to reflect the update
    self.widthSlider.value = size.width;
    self.heightSlider.value = size.height;
    [self sliderChanged:self.widthSlider];
    [self sliderChanged:self.heightSlider];
}

- (IBAction)confirm:(id)sender {
    //We chose the size
    self.heightSlider.value = self.widthSlider.value * self.aspectRatio;
    [CModel writeSizeWidth:self.widthSlider.value];
    [CModel writeSizeHeight:self.heightSlider.value];
    [self.delegate choseWidth:self.widthSlider.value height:self.heightSlider.value];
}
@end
