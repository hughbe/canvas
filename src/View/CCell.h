//
//  CCell.h
//  canvas
//
//  Created by Hugh Bellamy on 12/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CBezierContainer;
@protocol CCellDelegate;

@interface CCell : UICollectionViewCell

@property (nonatomic, weak) id<CCellDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIView *titleView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@property (nonatomic, weak) IBOutlet UIView *bottomView;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) IBOutlet UIView *optionsView;

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *videoPath;

@property (nonatomic, strong) id background;
@property (nonatomic, strong) NSArray *pathArray;

@property (nonatomic, assign) CGSize size;

- (void)showNew;
- (void)hideNew;
- (void)hideAll;

@end

@protocol CCellDelegate <NSObject>

- (void)deleteDrawing:(CCell*)cell;
- (void)editDrawing:(CCell*)cell;
- (void)shareDrawing:(CCell*)cell;
- (void)expandedDrawing:(CCell*)cell;

@end
