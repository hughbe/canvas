//
//  CChooseBrushViewController.m
//  canvas
//
//  Created by Hugh Bellamy on 27/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CChooseBrushViewController.h"

#import "CModel.h"
#import "CShapeCell.h"
#import "UIExtensions.h"
#import "CBrushTypeReusableView.h"

#import "WYStoryboardPopoverSegue.h"

#import "MBProgressHUDHelpers.h"
#import "WBNoticeViewHelpers.h"

@interface CChooseBrushViewController ()

@property (nonatomic, strong) NSArray *searchedTitles;

@end

@implementation CChooseBrushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchedTitles = [CModel brushPatternTitles];
    
    self.headerReferenceSize = CGSizeMake(0, self.navigationController.navigationBar.frame.size.height + 5);
    self.footerReferenceSize = CGSizeMake(0, 0);
}

- (void)viewDidAppear:(BOOL)animated {
    if(![CModel canUseMoreBrushes]) {
        [UIAlertView showWithTitle:@"Extra Features" message:@"Brush textures, shapes and blend modes are premium features. To access these without pay, please give an honest review of Canvas on the app store. It is simple and only takes half a minute, thank you." completion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if(buttonIndex == alertView.cancelButtonIndex) {
                [self.navigationController popViewControllerAnimated:YES];
            }
            else {
                SKStoreProductViewController *storeKitProductViewController = [[SKStoreProductViewController alloc]init];
                [self showHUDWithText:@"Loading" isNetwork:true];
                storeKitProductViewController.delegate = self;
                [storeKitProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @"777551805"} completionBlock:^(BOOL result, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error);
                        [self hideHUD:false];
                    }
                    else {
                        [self presentViewController:storeKitProductViewController animated:YES completion:^{
                            [self hideHUD:false];
                        }];
                    }
                }];
            }
        } style:UIAlertViewStyleDefault cancelButtonTitle:@"Cancel" otherButtonTitles:@"Review", nil];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.searchedTitles count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CShapeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.titleLabel.text = self.searchedTitles[indexPath.item];
    cell.view.backgroundColor = self.color;
    
    CBrushPatternType patternType = [[CModel brushPatternTitles]indexOfObject:cell.titleLabel.text];
    
    if(cell.view.subviews.count) {
        [cell.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    if(patternType == CBrushPatternDashed1 || patternType == CBrushPatternDashed2 || patternType == CBrushPatternDashed3 || patternType == CBrushPatternDashed4){
        NSString *fileName;
        switch (patternType) {
            case CBrushPatternDashed1:
                //Continuous (sausages)
                fileName = @"dash1";
                break;
            case CBrushPatternDashed2:
                //Split apart (e.g footsteps)
                fileName = @"dash2";
                break;
            case CBrushPatternDashed3:
                //Split more apart
                fileName = @"dash3";
                break;
            case CBrushPatternDashed4:
                //Split excessively apart
                fileName = @"dash4";
                break;
            default:
                break;
        }
        UIImageView *view = [[UIImageView alloc]initWithImage:[UIImage imageNamed:fileName]];
        view.frame = cell.view.bounds;
        cell.view.backgroundColor = nil;
        [cell.view addSubview:view];
        cell.layer.mask = nil;
    }
    else {
        if(patternType != CBrushPatternNormal) {
            NSString *fileName = [CModel fileNameForBrushPatternType:patternType];
            cell.view.backgroundColor = [[UIImage imageNamed:fileName] patternColor];
        }
        else {
            cell.view.backgroundColor = [UIColor blackColor];
        }
        //FIXME
        /*CGRect frame = cell.view.bounds;
        UIBezierPath *path = [UIBezierPath bezierPathFromShapeID:CShapeO frame:frame filled:NO rounded:YES]; //Sets up our dashed line
        
        CAShapeLayer *layer = [[CAShapeLayer alloc]init];
        layer.frame = cell.view.bounds;
        layer.path = path.CGPath;
        cell.view.layer.mask = layer;*/
    }
    
    return cell;
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [CModel writeCanUseMoreBrushes:YES];
    [self showSuccessNoticeWithTitle:@"Thanks for taking your time to rate Canvas. All feedback is appreciated"];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    if(!reusableview) {
        if (kind == UICollectionElementKindSectionHeader) {
            CBrushTypeReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"topBar" forIndexPath:indexPath];
            
            if([CModel lineCapStyle] == kCGLineCapRound) {
                //We have a rounded brush
                [headerView.lineCapControl setSelectedSegmentIndex:0];
                
            }
            else {
                //We have a squared brush
                [headerView.lineCapControl setSelectedSegmentIndex:1];
            }
            
            reusableview = headerView;
        }
    }
    return reusableview;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    CShapeCell *cell = (CShapeCell*)[collectionView cellForItemAtIndexPath:indexPath];
    CBrushPatternType brushID = [[CModel brushPatternTitles]indexOfObject:cell.titleLabel.text];
    
    [self.searchBar resignFirstResponder];
    [self.delegate brushWasChosen:brushID];
}

- (void)search:(UISearchBar*)searchBar {
    if(searchBar.text.length == 0) {
        self.searchedTitles = [CModel brushPatternTitles];
    }
    else {
        //Gets a list of matches that beginWith and contain our search
        NSMutableSet *beginMatches = [NSMutableSet setWithArray:[CModel brushPatternTitles]];
        NSMutableSet *containMatches = [NSMutableSet setWithArray:[CModel brushPatternTitles]];
        
        [beginMatches filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] %@", searchBar.text]];
        [containMatches filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", searchBar.text]];
        
        //Removes duplicates from the contains (as if it beginsWith something it also contains it)
        [containMatches minusSet:beginMatches];
        
        //BeginsWith takes priority over contains
        NSMutableArray *searchedArray = [[beginMatches allObjects]mutableCopy];
        [searchedArray addObjectsFromArray:[containMatches allObjects]];
        
        self.searchedTitles = searchedArray;
    }
    
    [self.collectionView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self search:searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self search:searchBar];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchedTitles = [CModel brushPatternTitles];
    [self.collectionView reloadData];
    
    [searchBar resignFirstResponder];
}

- (void)blendModeChosen:(CGBlendMode)blendMode name:(NSString *)blendModeName {
    [self.popover dismissPopoverAnimated:YES];
    [self.delegate blendModeChosen:blendMode name:blendModeName];
}

- (IBAction)blendMode:(UIBarButtonItem*)sender {
    [self performSegueWithIdentifier:@"blendMode" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"blendMode"]) {
        WYStoryboardPopoverSegue* popoverSegue = (WYStoryboardPopoverSegue*)segue;
        
        UINavigationController *destinationViewController = (UINavigationController *)segue.destinationViewController;
        destinationViewController.preferredContentSize = CGSizeMake(280, 280);
        
        CChooseBlendModeViewController *blendModeViewController = (CChooseBlendModeViewController*)destinationViewController.topViewController;
        blendModeViewController.delegate = self;
        
        blendModeViewController.blendModeTitle = [CModel brushBlendMode];
        blendModeViewController.backgroundColor = self.view.backgroundColor;
        
        self.popover = [popoverSegue popoverControllerWithSender:sender permittedArrowDirections:WYPopoverArrowDirectionUnknown animated:YES];
    }
}

@end
