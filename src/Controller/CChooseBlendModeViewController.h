//
//  CChooseBlendModeViewController.h
//  canvas
//
//  Created by Hugh Bellamy on 07/01/2014.
//  Copyright (c) 2014 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CChooseBlendModeDelegate <NSObject>

- (void)blendModeChosen:(CGBlendMode)blendMode name:(NSString *)blendModeName;

@end

@interface CChooseBlendModeViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property(weak, nonatomic) IBOutlet UIPickerView *blendModePicker;
@property(weak, nonatomic) IBOutlet UIButton *tickButton;

@property(nonatomic, strong) NSString *blendModeTitle;

@property(weak, nonatomic) id <CChooseBlendModeDelegate> delegate;

@property(nonatomic, strong) UIColor *backgroundColor;

@end
