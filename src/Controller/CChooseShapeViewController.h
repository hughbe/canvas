//
//  CChooseShapeViewController.h
//  canvas
//
//  Created by Hugh Bellamy on 17/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDrawingView.h"

@protocol CChooseShapeDelegate <NSObject>

- (void)choseShape:(CShapeType)shape filled:(BOOL)filled rounded:(BOOL)rounded;

@end

@interface CChooseShapeViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate, UISearchBarDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) id<CChooseShapeDelegate> delegate;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, weak) IBOutlet UISwitch *filled;
@property (nonatomic, weak) IBOutlet UISwitch *rounded;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *backgroundColor;

@end
