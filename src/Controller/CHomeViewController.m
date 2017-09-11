//
//  CHomeViewController.m
//  canvas
//
//  Created by Hugh Bellamy on 12/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

@import CoreData;

#import "CHomeViewController.h"

#import "CCell.h"
#import "CDrawingView.h"

#import "CModel.h"
#import "CDrawingViewController.h"
#import "WYStoryboardPopoverSegue.h"
#import "WYPopoverController.h"

#import "MBProgressHUD.h"
#import "WBSuccessNoticeView.h"

#import "CShareViewController.h"

@interface CHomeViewController ()

@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) WYPopoverController *sizePopover;
@property (strong, nonatomic) WYPopoverController *controller;

@property (strong, nonatomic) NSArray *searchedContent;

@property (nonatomic, assign) BOOL deleting;

@property (strong, nonatomic) UIColor *tintColor;
@end

@implementation CHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Sets up our gestures to show/hide the searchBar
    UISwipeGestureRecognizer *showSearchBarSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(search:)];
    showSearchBarSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:showSearchBarSwipeGestureRecognizer];
    
    self.model = [CModel new];
    self.searchedContent = self.model.source;
    self.searchBar.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self.tintColor) {
        [self.navigationController.navigationBar setBarTintColor:self.tintColor];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        NSMutableDictionary *dict = [self.navigationController.navigationBar.titleTextAttributes mutableCopy];
        [dict setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
        self.navigationController.navigationBar.titleTextAttributes = dict;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(!self.tintColor) {
        self.tintColor = self.navigationController.navigationBar.barTintColor;
    }
    
    if(!self.searchBar.hidden) {
        [self search:nil];
    }
    
    [self.navigationController.navigationBar setBarTintColor:nil];
    [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    NSMutableDictionary *dict = [self.navigationController.navigationBar.titleTextAttributes mutableCopy];
    [dict setObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;
}

- (WYPopoverController*)sizePopover {
    //Lazily instantiates our size popover
    if(!_sizePopover) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"size"];
        CSizeViewController *sizeViewController = (CSizeViewController*)navigationController.topViewController;
        sizeViewController.delegate = self;
        navigationController.preferredContentSize = CGSizeMake(self.view.frame.size.width, 100);
        _sizePopover = [[WYPopoverController alloc]initWithContentViewController:navigationController];
        _sizePopover.popoverContentSize = navigationController.preferredContentSize;
    }
    return _sizePopover;
}

- (UIImageView*)imageView {
    //Lazily instantiates our No Drawings imageView
    if(!_imageView) {
        UIImage *image = [UIImage imageNamed:@"No Drawings"];
        _imageView = [[UIImageView alloc]initWithImage:image];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        CGRect frame = CGRectZero;
        frame.size = CGSizeMake(200, 300);
        frame.origin.x = self.view.frame.size.width /2 - frame.size.width / 2;
        frame.origin.y = self.view.frame.size.height /2 - frame.size.height / 2;
        _imageView.frame = frame;
    }
    return _imageView;
}

- (void)showImageView {
    //Shows our No Drawings imageView
    if(!self.imageView.superview) {
        [self.view addSubview:self.imageView];
        if(!self.collectionView.hidden) {
            CGFloat duration = 0.0;
            if(self.deleting) {
                duration = 0.3;
            }
            
            [UIView animateWithDuration:duration animations:^{
                self.collectionView.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.collectionView.hidden = YES;
                self.deleting = NO;
            }];
        }
        else {
            self.collectionView.hidden = YES;
        }
    }
}

- (void)hideImageView {
    //Hides our No Drawings imageView
    [self.imageView removeFromSuperview];
    self.collectionView.alpha = 1.0;
    self.collectionView.hidden = NO;
}

- (void)search:(UISwipeGestureRecognizer*)swipeGestureRecognizer {
    __block BOOL hiding = NO;
    [UIView animateWithDuration:0.1 animations:^{
        //Moves the collectionView and searchBar together to show/hide the search
        CGRect searchBarFrame = self.searchBar.frame;
        
        CGFloat searchBarY = 0;
        CGFloat collectionViewY = 0;
        if(!self.searchBar.hidden) {
            //Hiding the searchBar
            searchBarY = -searchBarFrame.size.height;
            [self.searchBar resignFirstResponder];
            hiding = YES;
        }
        else {
            //Showing the searchBar
            collectionViewY = searchBarFrame.size.height;
            hiding = NO;
            self.searchBar.hidden = NO;
            [self.searchBar becomeFirstResponder];
        }
        searchBarFrame.origin.y = searchBarY;
        self.searchBar.frame = searchBarFrame;
        
        CGRect collectionViewFrame = self.collectionView.frame;
        collectionViewFrame.origin.y = collectionViewY;
        self.collectionView.frame = collectionViewFrame;
    } completion:^(BOOL finished) {
        if(hiding) {
            //If we've hidden the searchBar
            self.searchBar.hidden = YES;
        }
    }];
}

- (void)searchSource:(UISearchBar*)searchBar {
    if(searchBar.text.length == 0) {
        //We're not searching anything, so show everything
        self.searchedContent = self.model.source;
    }
    else {
        //Gets a list of matches that beginWith and contain our search
        NSMutableSet *beginMatches = [NSMutableSet setWithArray:self.model.source];
        NSMutableSet *containMatches = [NSMutableSet setWithArray:self.model.source];
        
        [beginMatches filterUsingPredicate:[NSPredicate predicateWithFormat:@"title BEGINSWITH[c] %@", searchBar.text]];
        [containMatches filterUsingPredicate:[NSPredicate predicateWithFormat:@"title CONTAINS[c] %@", searchBar.text]];
        
        //Removes duplicates from the contains (as if it beginsWith something it also contains it)
        [containMatches minusSet:beginMatches];
        
        //BeginsWith takes priority over contains
        NSMutableArray *searchedArray = [[beginMatches allObjects]mutableCopy];
        [searchedArray addObjectsFromArray:[containMatches allObjects]];
        
        self.searchedContent = searchedArray;
    }
    
    [self.collectionView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    //Shows our cancel button when editing
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //Hides our cancel button when editing
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    //Search
    [self searchSource:searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    //Search
    [self searchSource:searchBar];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //When we cancel, reset our searches and stop searching
    self.searchedContent = self.model.source;
    [self.collectionView reloadData];
    
    [searchBar resignFirstResponder];
    [self search:nil];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if([UIScreen mainScreen].bounds.size.height >= 568) {
            return CGSizeMake(260, 484);
        }
        else {
            CGFloat sizeHeight = 325 + 44 + 44;
            
            return CGSizeMake(250, sizeHeight);
        }
    }
    else {
        return CGSizeMake(616, 910);
    }
    return CGSizeZero;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = [self.searchedContent count];
    if(count == 0) {
        //If we have no entries, tell the user
        [self showImageView];
    }
    else {
        //If we have entries then hide the No Drawings imageViews
        [self hideImageView];
    }
    
    count++;
    return count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //Creates and formats the UI of our cell
    CCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.layer.borderWidth = 2.0;
    
    if(indexPath.row == (NSInteger)[self.searchedContent count]) {
        //The final cell either shows:
        if([self.searchedContent count] == 0) {
            //The 'No Drawings View'
            [cell hideAll];
            cell.layer.borderWidth = 0.0;
        }
        else {
            //Or The 'New Drawing View'
            [cell showNew];
        }
    }
    else {
        [cell hideNew];
        //Gets the data we need for the cell
        NSManagedObject *object = self.searchedContent[indexPath.row];
        
        //Gets the date and location of our drawing
        NSString *format = @"EEEE dd MMMM yyyy";
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = format;
        
        NSDate *rawDate = [object valueForKey:@"date"];
        NSString *date = [formatter stringFromDate:rawDate];
        
        //Gets the main image of our drawing (for display)
        NSString *ID = [object valueForKey:@"fileID"];
        NSString *filePath = [CModel documentPathForPNGFileName:ID];
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        UIImage *image = [UIImage imageWithData:fileData];
        cell.imageView.image = image;
        
        cell.dateLabel.text = date ;
        cell.titleLabel.text = [object valueForKey:@"title"];
        
        cell.ID = ID;
        cell.videoPath = [object valueForKey:@"videoPath"];
        cell.size = CGSizeFromString([object valueForKey:@"size"]);
        //Gets the pathArray for editing
        NSError *dataError;
        cell.pathArray = [[NSKeyedUnarchiver unarchiveObjectWithData:[object valueForKey:@"pathArray"]]deserialize];
        if(dataError) {
            NSLog(@"%@", dataError);
        }
        cell.delegate = self;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //If we tapped the new drawing cell, create a new drawing!
    if(indexPath.row == (NSInteger)[self.searchedContent count] && [self.searchedContent count] != 0) {
        [self createDrawing:self.navigationItem.rightBarButtonItem];
    }
}

- (IBAction)createDrawing:(UIBarButtonItem*)sender {
    //Start drawing
    [self.searchBar resignFirstResponder];
    [self.sizePopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:WYPopoverArrowDirectionUp animated:YES];
}

- (void)choseWidth:(float)width height:(float)height {
    //Dismiss the sizePopover and pass on the width and height values to the drawing!
    [self.sizePopover dismissPopoverAnimated:YES];
    
    NSArray *array = @[@(width), @(height)];
    NSArray *tips = [CModel tips];
    NSUInteger randomIndex = arc4random() % [tips count];
    NSString *randomTip = tips[randomIndex];
    
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    hud.label.text = randomTip;
    
    //Send initialization of drawing interface in background
    dispatch_async(dispatch_queue_create("create", NULL), ^{
        // when drawing interface is finally initialized,
        sleep(3);
        // hide indicator and present it on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];

            [self performSegueWithIdentifier:@"draw" sender:array];
        });
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //Which segue are we preparing for?
    if([segue.identifier isEqualToString:@"draw"]) {
        //We have to set ourselves up to be the delegate of the drawViewController
        CDrawingViewController *viewController = segue.destinationViewController;
        viewController.delegate = self;
        viewController.width = [sender[0] floatValue];
        viewController.height = [sender[1] floatValue];
        if([(NSArray*)sender count] > 3) {
            id background = sender[2];
            if([background isKindOfClass:[UIImage class]]) {
                viewController.image = background;
            }
            else {
                viewController.backgroundColor = background;
            }
            
            viewController.drawingTitle = sender[3];
            viewController.ID = sender[4];
            viewController.pathArray = sender[5];
            viewController.videoPath = sender[6];
        }
    }
    else if ([segue.identifier isEqualToString:@"help"]) {
        WYStoryboardPopoverSegue* popoverSegue = (WYStoryboardPopoverSegue*)segue;
        
        CShareViewController* destinationViewController = (CShareViewController *)segue.destinationViewController;
        destinationViewController.preferredContentSize = CGSizeMake(320, 280);
        destinationViewController.controller = self;        self.controller = [popoverSegue popoverControllerWithSender:sender permittedArrowDirections:WYPopoverArrowDirectionUnknown animated:YES];
        self.controller.delegate = self;
    }
}

- (void)drawingWasChosen:(UIImage *)drawing title:(NSString*)title background:(id)background size:(CGSize)size pathArray:(NSArray *)pathArray ID:(NSString *)ID videoPath:(NSString *)videoPath {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    hud.label.text = @"Saving...";

    //A drawing was chosen, save it
    [self.navigationController popViewControllerAnimated:YES];
    
    [self hideImageView];
    dispatch_async(dispatch_queue_create("saveUpdate", NULL), ^{
        __weak typeof(self) weakSelf = self;
        __weak typeof(self.model) weakModel = self.model;
        if(ID.length > 0) {
            //Editing
            [self.model updateDrawing:ID drawing:drawing title:title background:background size:size pathArray:pathArray videoPath:videoPath completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakModel loadSource];
                    weakSelf.searchedContent = weakModel.source;
                    [weakSelf.collectionView reloadData];
                    
                    [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                    
                    WBSuccessNoticeView *noticeView = [WBSuccessNoticeView successNoticeInView:weakSelf.view title:@"Drawing Saved"];
                    [noticeView show];
                });
            }];
        }
        else {
            //Adding
            [self.model addDrawing:drawing withTitle:title background:background size:size pathArray:pathArray videoPath:videoPath completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakModel loadSource];
                    weakSelf.searchedContent = weakModel.source;
                    [weakSelf.collectionView reloadData];
                    
                    WBSuccessNoticeView *noticeView = [WBSuccessNoticeView successNoticeInView:weakSelf.view title:@"Drawing Saved"];
                    [noticeView show];
                });
            }];
        }
    });
}

-(void)shareDrawing:(CCell *)cell {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    hud.label.text = @"Loading...";
    
    // create new dispatch queue in background
    dispatch_async(dispatch_queue_create("shareDrawing", NULL), ^{
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc]initWithActivityItems:@[cell.titleLabel.text, cell.imageView.image] applicationActivities:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            [self presentViewController:activityViewController animated:YES completion:nil];
        });
    });
}

- (void)editDrawing:(CCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    NSManagedObject *object = self.searchedContent[indexPath.row];
    
    //Sets the background (type variable) for editing
    id background;
    NSString *backgroundString = [object valueForKey:@"background"];
    NSString *backgroundType = [backgroundString substringToIndex:1];
    
    if([backgroundType isEqualToString:@"c"]) {
        //Color background
        NSString *backgroundInfo = [backgroundString substringFromIndex:1];
        background = UIColorFromNSString(backgroundInfo);
    }
    else if([backgroundType isEqualToString:@"i"]) {
        //Image background
        NSString *backgroundFilePath = [CModel documentPathForPNGFileName:backgroundString];
        background = [UIImage imageWithContentsOfFile:backgroundFilePath];
    }
    
    NSArray *sender = @[@(cell.size.width), @(cell.size.height), background, cell.titleLabel.text, cell.ID, cell.pathArray, cell.videoPath];
    
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    hud.label.text = @"Editing...";
    
    //Sends initialization of drawing interface in background
    dispatch_async(dispatch_queue_create("editImage", NULL), ^{
        //When drawing interface is finally initialized, hides the indicator and present it on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];

            [self performSegueWithIdentifier:@"draw" sender:sender];
        });
    });
}

- (void)deleteDrawing:(CCell *)cell {
    //Tell the model to remove the drawing then delete it from our collectionView
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Deletion is permenant"  message:@"Please confirm." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        //Delete
        [self.model removeDrawingWithID:cell.ID completion:^{
            self.searchedContent = self.model.source;
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            self.deleting = YES;
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        }];
    }];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
    }];
    
    [alert addAction:delete];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)expandedDrawing:(CCell *)cell {
    if(!self.searchBar.hidden) {
        [self search:nil];
    }
}
@end
