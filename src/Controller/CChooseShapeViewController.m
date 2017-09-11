//
//  CChooseShapeViewController.m
//  canvas
//
//  Created by Hugh Bellamy on 17/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CChooseShapeViewController.h"
#import "CShapeCell.h"
#import "UIExtensions.h"
#import "CModel.h"

@interface CChooseShapeViewController()

@property (nonatomic, strong) NSArray *searchedTitles;

@end

@implementation CChooseShapeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchedTitles = [CModel shapeTitles];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.searchedTitles count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CShapeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.titleLabel.text = self.searchedTitles[indexPath.item];
    //FIXME
    /*NSInteger shapeID = [[CModel shapeTitles] indexOfObject:cell.titleLabel.text];
    CGRect frame = cell.view.bounds;
    UIBezierPath *path = [UIBezierPath bezierPathFromShapeID:shapeID frame:frame filled:self.filled.selected rounded:!self.rounded.selected];
    
    CAShapeLayer *layer = [[CAShapeLayer alloc]init];
    layer.frame = cell.view.bounds;
    layer.path = path.CGPath;
    cell.view.layer.mask = layer;
    cell.view.backgroundColor = self.color;*/
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchBar resignFirstResponder];
    [self.delegate choseShape:[[CModel shapeTitles] indexOfObject:self.searchedTitles[indexPath.row]] filled:self.filled.selected rounded:!self.rounded.selected];
}

- (void)search:(UISearchBar*)searchBar {
    if(searchBar.text.length == 0) {
        self.searchedTitles = [CModel shapeTitles];
    }
    else {
        //Gets a list of matches that beginWith and contain our search
        NSMutableSet *beginMatches = [NSMutableSet setWithArray:[CModel shapeTitles]];
        NSMutableSet *containMatches = [NSMutableSet setWithArray:[CModel shapeTitles]];
        
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
    self.searchedTitles = [CModel shapeTitles];
    [self.collectionView reloadData];
    
    [searchBar resignFirstResponder];
}
@end
