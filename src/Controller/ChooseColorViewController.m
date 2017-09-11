//
//  DIChooseColorViewController.m
//  Diary
//
//  Created by Hugh Bellamy on 01/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "ChooseColorViewController.h"

@interface ChooseColorViewController ()

- (void)hideBorders;

@end

@implementation ChooseColorViewController

- (IBAction)choseColor:(id)sender {
    //Tells the delegate we chose a color
    [self.delegate choseColor:self.colorPicker.selectionColor type:self.type];
}

- (IBAction)brightnessChanged:(UISlider*)slider {
    //Brightness changed, so update the colorPicker's brightness
    self.colorPicker.brightness = slider.value;
}

- (void)colorPickerDidChangeSelection:(RSColorPickerView *)cp {
    //Updates the background colors to show the changes
    self.view.backgroundColor = cp.selectionColor;
    cp.backgroundColor = cp.selectionColor;
    
    //Updates the brightness value
    self.brightnessSlider.value = cp.brightness;
    
    //Hide the borders surrounding our
    [self hideBorders];

    for(UIView *view in [self.scrollView.subviews copy]) {
        if ([cp.selectionColor isEqual:view.backgroundColor]) {
            view.layer.borderWidth = 2.0f;
        }
    }
}

- (void)definedColorPressed:(UITapGestureRecognizer*)gestureRecognizer {
    //When we press a color, update it and hide the borders of all other color tap views
    self.colorPicker.selectionColor = gestureRecognizer.view.backgroundColor;
    [self hideBorders];
    gestureRecognizer.view.layer.borderWidth = 2.0f;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Creates our colorPicker
    CGRect rect = CGRectIntegral(CGRectMake(5, 5, self.view.frame.size.width * (3.0 / 4),  self.view.frame.size.height * (3.0 / 4)));
    self.colorPicker = [[RSColorPickerView alloc]initWithFrame:rect];
    self.colorPicker.selectionColor = self.initialColor;
    self.colorPicker.opacity = 1.0;
    [self.colorPicker setCropToCircle:YES];
    [self.colorPicker setDelegate:self];
    [self.view addSubview:self.colorPicker];
    
    //Rotates our brightness slider and locates it correctly
    self.brightnessSlider.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    self.brightnessSlider.value = self.colorPicker.brightness;
    
    CGRect frame = self.brightnessSlider.frame;
    frame.origin = CGPointMake(15, 25);
    self.brightnessSlider.frame = frame;
    
    //Adds a border to our brightness container
    self.brightnessContainer.layer.borderColor = [UIColor blueColor].CGColor;
    self.brightnessContainer.layer.borderWidth = 5.0f;
    self.brightnessContainer.layer.cornerRadius = 15.0f;
    
    //Sets us up to select colors from preset list
    for(UIView *view in [self.scrollView.subviews copy]) {
        [view addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(definedColorPressed:)]];
    }
    
    //Autosizes the scrollView to fit content
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.scrollView.contentSize = contentRect.size;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    for(UIView *view in [self.scrollView.subviews copy]) {
        if([view.backgroundColor isEqual:self.initialColor]) {
            view.layer.borderWidth = 2.0f;
        }
    }
}

- (void)hideBorders {
    //All subviews in our scrollView will have their borders removed
    for(UIView *view in [self.scrollView.subviews copy]) {
        view.layer.borderWidth = 0.0f;
    };
}

@end
