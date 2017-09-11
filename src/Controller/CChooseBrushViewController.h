//
//  CChooseBrushViewController.h
//  canvas
//
//  Created by Hugh Bellamy on 27/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDrawingView.h"
#import "CChooseBlendModeViewController.h"
#import <StoreKit/StoreKit.h>
@class WYPopoverController;
@protocol CChooseBrushDelegate<NSObject>

- (void)brushWasChosen:(CBrushPatternType)brushType;

@end

@interface CChooseBrushViewController : UIViewController<CChooseBlendModeDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, weak) id<CChooseBrushDelegate, CChooseBlendModeDelegate> delegate;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@property (nonatomic, assign) CGSize headerReferenceSize;
@property (nonatomic, assign) CGSize footerReferenceSize;

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *backgroundColor;

@property (nonatomic, strong) WYPopoverController *popover;

@end
