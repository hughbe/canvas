//
//  CChooseBlendModeViewController.m
//  canvas
//
//  Created by Hugh Bellamy on 07/01/2014.
//  Copyright (c) 2014 Hugh Bellamy. All rights reserved.
//

#import "CChooseBlendModeViewController.h"

#import "CModel.h"
#import "UIImage+Additions.h"

@interface CChooseBlendModeViewController ()

@end

@implementation CChooseBlendModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImage *tintedImage = [self.tickButton.currentBackgroundImage add_tintedImageWithColor:[UIColor whiteColor] style:ADDImageTintStyleKeepingAlpha];
    [self.tickButton setBackgroundImage:tintedImage forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!self.blendModeTitle) {
        self.blendModeTitle = @"Normal";
    }

    [self.blendModePicker reloadAllComponents];
    [self.blendModePicker selectRow:[[CModel blendModeTitles] indexOfObject:self.blendModeTitle] inComponent:0 animated:NO];
    self.blendModeTitle = nil;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [[CModel blendModeTitles] count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [CModel blendModeTitles][(NSUInteger) row];
}

- (IBAction)confirm:(id)sender {
    NSInteger selectedRowIndex = [self.blendModePicker selectedRowInComponent:0];
    NSString *selectedRowTitle = [self pickerView:self.blendModePicker titleForRow:selectedRowIndex forComponent:0];
    CGBlendMode chosenBlendMode = [CModel blendModeForTitle:selectedRowTitle];

    [self.delegate blendModeChosen:chosenBlendMode name:selectedRowTitle];
}

@end
