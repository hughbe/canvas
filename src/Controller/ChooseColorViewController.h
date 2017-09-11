//
//  DIChooseColorViewController.h
//  Diary
//
//  Created by Hugh Bellamy on 01/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSColorPickerView.h"

typedef NS_ENUM(NSInteger, CColorType) {
    CColorTypeStroke,
    CColorTypeBackground,
};

@protocol ChooseColorDelegate <NSObject>

- (void)choseColor:(UIColor*)color type:(CColorType)type;

@end

@interface ChooseColorViewController : UIViewController<RSColorPickerViewDelegate>

@property (nonatomic, weak) id<ChooseColorDelegate> delegate;

@property (nonatomic, strong) RSColorPickerView *colorPicker;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, weak) IBOutlet UIView *brightnessContainer;
@property (nonatomic, weak) IBOutlet UISlider *brightnessSlider;
@property (nonatomic, strong) UIColor *initialColor;
@property (nonatomic, strong) UIColor *resetColor;

@property (nonatomic, assign) CColorType type;

@end
