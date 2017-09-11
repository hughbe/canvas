//
//  CHomeViewController.h
//  canvas
//
//  Created by Hugh Bellamy on 12/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CModel;

#import "CCell.h"
#import "CDrawingViewController.h"
#import "CSizeViewController.h"
#import "WYPopoverController.h"

@interface CHomeViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, CDrawViewControllerDelegate, CChooseSizeDelegate, CCellDelegate, WYPopoverControllerDelegate>

@property (strong, nonatomic) CModel *model;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end
