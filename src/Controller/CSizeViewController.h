//
//  CSizeViewController.h
//  canvas
//
//  Created by Hugh Bellamy on 13/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CChooseSizeDelegate <NSObject>

-(void)choseWidth:(float)width height:(float)width;

@end

@interface CSizeViewController : UIViewController

@property (nonatomic, weak) id<CChooseSizeDelegate> delegate;

@property (nonatomic, weak) IBOutlet UISlider *widthSlider;
@property (nonatomic, weak) IBOutlet UILabel *widthlabel;

@property (nonatomic, weak) IBOutlet UISlider *heightSlider;
@property (nonatomic, weak) IBOutlet UILabel *heightLabel;

@property (nonatomic, assign) CGSize resetSize;

@end
