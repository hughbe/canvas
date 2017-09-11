//
//  CViewController.m
//  canvas
//
//  Created by Hugh Bellamy on 09/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

@import AVFoundation;
@import AVKit;
@import CoreMedia;
@import MediaPlayer;

#import "CDrawingViewController.h"

#import "CModel.h"
#import "CBrushView.h"

#import "CShapeCell.h"

#import "UIImage+Additions.h"
#import "UIView+Borders.h"
#import "WBErrorNoticeView.h"
#import "WBSuccessNoticeView.h"
#import "WYPopoverController.h"

@interface CDrawingViewController ()

@property (nonatomic, assign) BOOL animating;
@property (nonatomic, assign) BOOL showingAlert;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (strong, nonatomic) WYPopoverController *sizePopover;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;


@property (strong, nonatomic) UIImage *backupImage;

@end

@implementation CDrawingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Sets up our stroke variables for the first time
    [CModel setupFirstUse:self.drawingBackgroundView.backgroundColor];
    
    //Gets the saved stroke variables
    self.drawingView.color = [CModel strokeColor];
    self.drawingView.lineWidth = [CModel lineWidth];
    self.drawingView.opacity = [CModel opacity];
    
    self.drawingBackgroundView.backgroundColor = [CModel backgroundColor];
    
    self.drawingView.lineCap = [CModel lineCapStyle];
    self.drawingView.brushPatternType = [CModel brushPatternType];
    self.drawingView.blendMode = [CModel blendModeForTitle:[CModel brushBlendMode]];
    
    //Sets up our drawingView's delegate to receieve undoRedo notifications
    self.drawingView.delegate = self;
    
    //Sets up our undo and redo buttons
    self.undoButton.enabled = NO;
    self.redoButton.enabled = NO;
    
    UIImage *cancelImage = [self.cancelButton.currentBackgroundImage add_tintedImageWithColor:[UIColor blackColor] style:ADDImageTintStyleOverAlpha];
    [self.cancelButton setBackgroundImage:cancelImage forState:UIControlStateNormal];
    
    UIImage *confirmImage = [self.confirmButton.currentBackgroundImage add_tintedImageWithColor:[UIColor blackColor] style:ADDImageTintStyleOverAlpha];
    [self.confirmButton setBackgroundImage:confirmImage forState:UIControlStateNormal];
    
    //Sets up our UI
    [self hideAll];
    
    [self.drawingToolbar addBottomBorderWithHeight:1.0 andColor:[UIColor darkGrayColor]];
    [self.opacityLineWidthToolbar addBottomBorderWithHeight:1.0 andColor:[UIColor darkGrayColor]];
    [self.shapeBackgroundToolbar addBottomBorderWithHeight:1.0 andColor:[UIColor darkGrayColor]];
    
    //Sets up our scrollView to not scroll immediately
    self.containerView.delegate = self;
    self.containerView.scrollEnabled = NO;
    self.containerView.zoomScale = 1.0;
    
    //Adds a two-finger panning option to the scrollView to scroll it
    self.containerView.panGestureRecognizer.minimumNumberOfTouches = 2;
    self.containerView.panGestureRecognizer.maximumNumberOfTouches = 2;
    
    //Creates our imagePicker in the background
    dispatch_queue_t queue = dispatch_queue_create("shareDrawing", NULL);
    dispatch_async(queue, ^{
        self.imagePicker = [[UIImagePickerController alloc]init];
    });
    
    //Sets up our drawing view background
    if(self.image) {
        self.drawingBackgroundView.image = self.image;
        self.image = nil;
    }
    else if(self.backgroundColor) {
        self.drawingBackgroundView.backgroundColor = self.backgroundColor;
        self.backgroundColor = nil;
    }
    
    if([self.videoPath isEqualToString:@"nil"] || !self.videoPath.length) {
        self.playButton.hidden = YES;
    }
    
    //Sets up our drawing view paths
    if([self.pathArray count] > 0) {
        self.drawingView.pathArray = [self.pathArray mutableCopy];
        self.pathArray = nil;
        [self.drawingView drawBitmap];
        
        self.drawingView.canUndo = YES;
        [self updateUndoRedo];
    }
    
    self.drawingIncrementalView.image = nil;
    self.drawingView.incrementalView = self.drawingIncrementalView;
    
    self.drawingBackgroundView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIImage *playImage = [[UIImage imageNamed:@"play"]add_tintedImageWithColor:[UIColor blueColor] style:ADDImageTintStyleOverAlpha];
    [self.playButton setBackgroundImage:playImage forState:UIControlStateNormal];
     
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(lineCapChanged:) name:LINE_CAP_CHANGED_NOTIFICATION_NAME object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerWillExitFullscreenNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self stop];
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:MPMoviePlayerPlaybackDidFinishNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self stop];
    }];
    
    [self.drawingView drawBitmap];
    
    [self prepareFrames];
}

- (void)stop {
    self.brushView.hidden = NO;
    
    UIImage *playImage = [[UIImage imageNamed:@"play"]add_tintedImageWithColor:[UIColor blueColor] style:ADDImageTintStyleOverAlpha];
    [self.playButton setBackgroundImage:playImage forState:UIControlStateNormal];
    [self.playerLayer removeFromSuperlayer];
    self.player = nil;
    self.drawingIncrementalView.userInteractionEnabled = YES;
    self.playButton.tag = 0;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (WYPopoverController*)sizePopover {
    if(!_sizePopover) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"size"];
        navigationController.preferredContentSize = CGSizeMake(self.view.frame.size.width, 260);
        
        CSizeViewController *sizeViewController = (CSizeViewController*)navigationController.topViewController;
        sizeViewController.delegate = self;
        sizeViewController.resetSize = CGSizeMake(self.width, self.height);
        
        WYPopoverBackgroundView *popoverBackground = [WYPopoverBackgroundView appearance];
        popoverBackground.tintColor = [UIColor orangeColor];
        _sizePopover = [[WYPopoverController alloc]initWithContentViewController:navigationController];
    }
    return _sizePopover;
}

- (void)prepareFrames {
    //Define an aspect ratio and size the scrollView to suit the aspectRatio
    float aspectRatio = self.height / self.width;
    
    //Sets up the possible zoom scales
    self.containerView.maximumZoomScale = 2.25;
    self.containerView.zoomScale = 1.0;
    self.containerView.contentOffset = CGPointZero;
    self.containerView.contentSize = CGSizeMake(self.width, self.width * aspectRatio);
    self.containerView.frame = self.view.bounds;
    
    //Creates our views as large as the image
    CGRect drawingViewFrame = CGRectZero;
    drawingViewFrame.size = self.containerView.contentSize;
    self.drawingView.frame = drawingViewFrame;
    self.drawingIncrementalView.frame = drawingViewFrame;
    self.drawingBackgroundView.frame = drawingViewFrame;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.containerView.minimumZoomScale = self.view.frame.size.height / self.height;
    self.drawingView.layer.borderWidth = 2.0;
    [self prepareFrames];
}

- (void)choseWidth:(float)width height:(float)height {
    //Update our size
    [self.sizePopover dismissPopoverAnimated:YES];
    
    void(^changeSize)() = ^(){
        self.width = width;
        self.height = height;
        [self prepareFrames];
        self.containerView.minimumZoomScale = self.view.frame.size.height / self.height;
        [self.drawingView drawBitmap];
    };
    
    if(width < self.width || height < self.height) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Size" message:@"Your chosen size is smaller than your current size. Your drawing may be cut off if you proceed with this resize" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *resize = [UIAlertAction actionWithTitle:@"Resize" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            changeSize();
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:resize];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        changeSize();
    }
}

- (void)panScrollView:(UIPanGestureRecognizer*)panGestureRecognizer {
    CGPoint point = [panGestureRecognizer locationInView:self.drawingView];
    point.x = MAX(0, point.x - self.containerView.frame.size.width);
    point.x = MAX(0, point.y - self.containerView.frame.size.height);
    self.containerView.contentOffset = point;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    //We can zoom in our drawingBackgroundView
    return self.drawingBackgroundView;
}

- (void)updateUndoRedo {
    //If we can undo, enable the undoButton
    self.undoButton.enabled = self.drawingView.canUndo;
    
    //If we can redo, enable the redoButton
    self.redoButton.enabled = self.drawingView.canRedo;
}

- (IBAction)undo:(id)sender {
    //Undos the drawingView progess
    [self.drawingView undo];
}

- (IBAction)redo:(id)sender {
    //Redos the drawingView progress
    [self.drawingView redo];
}

- (IBAction)download:(id)sender {
    //Writes this drawing to the savedAlbums and notifies the user
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Save Drawing" message:@"Do you want to save this drawing to your Photo Library?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *save = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        UIImage *image = [self.drawingView renderImageWithContainer:self.containerView opaque:self.containerView.opaque];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        WBSuccessNoticeView *noticeView = [WBSuccessNoticeView successNoticeInView:self.view title:@"Saved to Photo Library"];
        [noticeView show];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:save];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)cancel:(id)sender {
    //Shows a confirmation to the user and then cancels the drawing
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cancel" message:@"Abandon your art? Unsaved changes will be lost?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *abandon = [UIAlertAction actionWithTitle:@"Abandon" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Don't Abandon" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:abandon];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)confirm:(id)sender {
    //Shows a alertView with textField to the user asking for a title for the artwork
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Choose a Title" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField* textField) {
        textField.placeholder = @"Title";
        textField.text = self.drawingTitle;
        
        textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    }];
    
    UIAlertAction *save = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        UITextField *titleTextField = alert.textFields[0];
        if ([titleTextField.text isEqualToString:@""]) {
            WBErrorNoticeView *noticeView = [WBErrorNoticeView errorNoticeInView:self.containerView title:@"You need a Title" message:@"Try something deep, like 'Untitled' or 'What is Life?'"];
            [noticeView show];
        } else {
            UIImage *drawing = [self.drawingView renderImageWithContainer:self.containerView opaque:self.containerView.opaque];
            id background;
            if(self.drawingBackgroundView.image) {
                background = self.drawingBackgroundView.image;
            }
            else {
                background = self.drawingBackgroundView.backgroundColor;
            }
            
            [self.delegate drawingWasChosen:drawing title:titleTextField.text background:background size:self.drawingView.bounds.size pathArray:self.drawingView.pathArray ID:self.ID videoPath:self.videoPath];
        }
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:save];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:TRUE completion:nil];
}

- (IBAction)eraseAll:(id)sender {
    //Warns the user that erasing the entire screen is permenant
    if(!self.showingAlert ) {
        self.showingAlert = YES;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erase Drawing" message:@"Are you sure you wish to erase the entire drawing? This cannot be undone" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *erase = [UIAlertAction actionWithTitle:@"Erase" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            self.showingAlert = NO;
            [self.drawingView eraseAll];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Don't Erase" style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:erase];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

- (IBAction)showColor:(UIButton*)sender {
    //Show stroke color picker
    NSArray *array = @[NSStringFromUIColor(self.drawingView.color), NSStringFromUIColor([UIColor brownColor]), @(0)];
    [self performSegueWithIdentifier:@"color" sender:array];
}

- (IBAction)sliderChanged:(UISlider*)slider {
    //Displays our slider's value readably
    [self.opacityLineWidthLabel setTitle:[NSString stringWithFormat:@"%.2f", slider.value]];
    if(self.lineWidthButton.tintColor == [UIColor redColor]) {
        //Update the lineWidth
        [CModel writeLineWidth:slider.value];
        self.drawingView.lineWidth = slider.value;
    }
    else {
        //Update the opacity
        [CModel writeOpacity:slider.value];
        self.drawingView.opacity = slider.value;
    }
}

- (IBAction)brushType:(id)sender {
    [self performSegueWithIdentifier:@"brush" sender:nil];
}

- (void)lineCapChanged:(NSNotification*)notification {
    self.drawingView.lineCap = (CGLineCap)[notification.object integerValue];
}

- (void)brushWasChosen:(CBrushPatternType)brushType {
    [CModel writeBrushPatternType:brushType];
    self.drawingView.brushPatternType = brushType;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)blendModeChosen:(CGBlendMode)blendMode name:(NSString *)blendModeName {
    [CModel writeBrushBlendMode:blendModeName];
    self.drawingView.blendMode = blendMode;
}

- (IBAction)changeBackground:(UIBarButtonItem*)sender {
    //Show the actionSheet choosing the background source
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Choose Background Sources" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        //Makes sure we have a Camera
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Camera" message:@"Your device lacks a camera" preferredStyle:UIAlertControllerStyleAlert];
            
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
        self.imagePicker.delegate = self;
        self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *photoLibrary = [UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        //Makes sure we have a Photo Library
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Photo Library" message:@"Your device lacks a photo library" preferredStyle:UIAlertControllerStyleAlert];
            
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        self.imagePicker.delegate = self;
        self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *color = [UIAlertAction actionWithTitle:@"Color" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        NSArray *array = @[NSStringFromUIColor(self.drawingBackgroundView.backgroundColor), NSStringFromUIColor([CModel defaultBackgroundColor]), @(1)];
        [self performSegueWithIdentifier:@"color" sender:array];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:camera];
    [alert addAction:photoLibrary];
    [alert addAction:color];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteVideoWithPath:(NSString *)path {
    if(path.length) {
        NSError *error;
        if([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
            if(error) {
                NSLog(@"%@", error);
            }
        }
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //Updates our background image
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self deleteVideoWithPath:self.videoPath];
    
    if(image) {
        //Image Handling
        self.drawingBackgroundView.image = image;
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            //We ask the user to save the photo to the camera roll
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Save Photo" message:@"Do you want to save this photo to your camera roll?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
            }];
            
            UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
            
            [alert addAction:yes];
            [alert addAction:no];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        self.playButton.hidden = YES;
    }
    else {
        //Video Handling
        NSURL *filePath = info[UIImagePickerControllerMediaURL];
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            //We ask the user to save the video to the camera roll
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Save Video" message:@"Do you want to save this recorded video to your camera roll?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([filePath absoluteString])) {
                    UISaveVideoAtPathToSavedPhotosAlbum([filePath absoluteString], nil, nil, NULL);
                }
            }];
            
            UIAlertAction *no = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
            
            [alert addAction:yes];
            [alert addAction:no];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        if(self.videoID == nil) {
            self.videoID = [[[CModel alloc]init]getNewID];
        }
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:filePath options:nil];
        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        CMTime time = CMTimeMakeWithSeconds(0.0, 60);
        NSError *thumbnailError;
        CMTime actualTime;
        
        CGImageRef thumbnailImage = [gen copyCGImageAtTime:time actualTime:&actualTime error:&thumbnailError];
        if(thumbnailError) {
            NSLog(@"%@", thumbnailError);
        }
        
        UIImage *thumb = [[UIImage alloc] initWithCGImage:thumbnailImage];
        CGImageRelease(thumbnailImage);
        self.drawingBackgroundView.image = thumb;
        
        self.videoPath = [CModel documentPathForFileName:[NSString stringWithFormat:@"%@.mov", self.videoID, nil]];
        
        NSError *error;
        if([[NSFileManager defaultManager]fileExistsAtPath:self.videoPath]) {
            NSError *deleteError;
            [[NSFileManager defaultManager]removeItemAtPath:self.videoPath error:&deleteError];
            if(deleteError) {
                NSLog(@"%@", deleteError);
            }
        }
        
        [[NSFileManager defaultManager]copyItemAtPath:[filePath path] toPath:self.videoPath error:&error];
        if(error) {
            NSLog(@"%@", error);
        }
        self.playButton.hidden = NO;
    }
}

- (IBAction)play:(UIButton*)sender {
    if(sender.tag == 0) {
        //Play
        self.brushView.hidden = YES;
        
        NSURL *url = [NSURL fileURLWithPath:self.videoPath];
        self.player = [[AVPlayer alloc]initWithURL:url];
        
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.drawingBackgroundView.bounds;
        
        [self.drawingBackgroundView.layer addSublayer:self.playerLayer];
        [self.player play];
        
        UIImage *playButtonImage = [[UIImage imageNamed:@"stop"]add_tintedImageWithColor:[UIColor blueColor] style:ADDImageTintStyleOverAlpha];
        [self.playButton setBackgroundImage:playButtonImage forState:UIControlStateNormal];

        sender.tag = 1;
        self.drawingIncrementalView.userInteractionEnabled = NO;
    }
    else {
        //Stop
        [self.player pause];
    }
}


- (IBAction)changeSize:(UIButton*)sender {
    [self.sizePopover presentPopoverFromBarButtonItem:self.sizeBarButton permittedArrowDirections:WYPopoverArrowDirectionUp animated:YES];
}

- (void)choseColor:(UIColor *)color type:(CColorType)type {
    //Dismisses our picker
    [self.navigationController popViewControllerAnimated:YES];
    if(type == CColorTypeStroke) {
        //Updates our stroke color
        [CModel writeStrokeColor:color];
        self.drawingView.color = color;
    }
    else {
        //Updates our background color
        [CModel writeBackgroundColor:color];
        self.drawingBackgroundView.backgroundColor = color;
        self.drawingBackgroundView.image = nil;
        self.playButton.hidden = YES;
    }
}

- (void)removeBrushSelections {
    for(UIView *view in [self.brushView.subviews copy]) {
        if(![view isMemberOfClass:[UIButton class]]) {
            continue;
        }
        
        UIButton *button = (UIButton*)view;
        UIImage *tintedImage = [button.currentBackgroundImage add_tintedImageWithColor:[UIColor blackColor] style:ADDImageTintStyleOverAlpha];
        [button setBackgroundImage:tintedImage forState:UIControlStateNormal];
    }
}

- (IBAction)changeBrushMode:(UIButton*)sender {
    //Deselects all of our brush modes
    if(sender.tag != 4) {
        [self removeBrushSelections];
        
        UIImage *sendImage = [sender.currentBackgroundImage add_tintedImageWithColor:[UIColor redColor] style:ADDImageTintStyleOverAlpha];
        [sender setBackgroundImage:sendImage forState:UIControlStateNormal];
    }
    
    if (sender.tag == 0 || sender.tag == 1) {
        //Erase
        //Checks if we're erasing or not currently
        if(sender.tag == 0) {
            //We're starting to erase
            sender.tag = 1;
            
            UIImage *senderImage = [[UIImage imageNamed:@"erase"]add_tintedImageWithColor:[UIColor redColor] style:ADDImageTintStyleOverAlpha];
            [sender setBackgroundImage:senderImage forState:UIControlStateNormal];
            
            self.drawingView.brushType = CBrushTypeEraser;
            self.drawingView.backupColor = self.drawingView.color;
            self.drawingView.color = [UIColor clearColor];
        }
        else {
            //We're no longer erasing
            sender.tag = 0;
            
            UIImage *senderImage = [[UIImage imageNamed:@"erase"]add_tintedImageWithColor:[UIColor redColor] style:ADDImageTintStyleOverAlpha];
            [sender setBackgroundImage:senderImage forState:UIControlStateNormal];
            self.drawingView.color = self.drawingView.backupColor;
            self.drawingView.brushType = CBrushTypeNormal;
            
            UIImage *normalButtonImage = [self.brushView.normalButton.currentBackgroundImage add_tintedImageWithColor:[UIColor redColor] style:ADDImageTintStyleOverAlpha];
            [self.brushView.normalButton setBackgroundImage:normalButtonImage forState:UIControlStateNormal];
        }
    }
    
    if(self.drawingView.brushType == CBrushTypeEraser && sender.tag != 0 && sender.tag != 1) {
        //Stop erasing
        [self changeBrushMode:self.brushView.eraseButton];
    }
    if(sender.tag == 2) {
        //Normal brush
        self.drawingView.brushType = CBrushTypeNormal;
    }
    else if(sender.tag == 3) {
        //Lines
        self.drawingView.brushType = CBrushTypeStraightLine;
    }
    else if(sender.tag == 4) {
        //Shape
        [self performSegueWithIdentifier:@"shape" sender:nil];
    }
    else if (sender.tag == 5) {
        //Fill
        self.drawingView.brushType = CBrushTypeFill;
    }
    else if(sender.tag == 6) {
        //Move
        self.drawingView.brushType = CBrushTypeMove;
    }
    else if(sender.tag == 7) {
        //Delete
        self.drawingView.brushType = CBrushTypeDelete;
    }
}

-(void)choseShape:(CShapeType)shape filled:(BOOL)filled rounded:(BOOL)rounded {
    //We're in the shape mode
    [self removeBrushSelections];
    
    UIImage *shapeImage = [self.brushView.shapeButton.currentBackgroundImage add_tintedImageWithColor:[UIColor redColor] style:ADDImageTintStyleOverAlpha];
    [self.brushView.shapeButton setBackgroundImage:shapeImage forState:UIControlStateNormal];
    
    self.drawingView.brushType = CBrushTypeShape;
    self.drawingView.shape = CShapeMake(shape, filled, rounded);
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"color"]) {
        ChooseColorViewController *viewController = segue.destinationViewController;
        viewController.delegate = self;
        NSArray *array = sender;
        viewController.initialColor = UIColorFromNSString(array[0]);
        viewController.resetColor =  UIColorFromNSString(array[1]);
        viewController.type = [array[2] integerValue];
    }
    else if([segue.identifier isEqualToString:@"shape"]) {
        CChooseShapeViewController *shapeViewController = segue.destinationViewController;
        shapeViewController.delegate = self;
        shapeViewController.color = self.drawingView.color;
        shapeViewController.backgroundColor = self.drawingBackgroundView.backgroundColor;
    }
    else if ([segue.identifier isEqualToString:@"brush"]) {
        CChooseBrushViewController *brushViewController = segue.destinationViewController;
        brushViewController.delegate = self;
        brushViewController.color = self.drawingView.color;
        brushViewController.backgroundColor = self.drawingBackgroundView.backgroundColor;
    }
}


- (IBAction)showOpacity:(UIButton*)button {
    //Shows that we have selected opacity
    button.tintColor = [UIColor redColor];
    self.lineWidthButton.tintColor = [UIColor blackColor];
    button.tag = -3;
    
    UIImage *buttonImage = [button.currentBackgroundImage add_tintedImageWithColor:button.tintColor style:ADDImageTintStyleOverAlpha];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    UIImage *lineWidthImage = [self.lineWidthButton.currentBackgroundImage add_tintedImageWithColor:self.lineWidthButton.tintColor style:ADDImageTintStyleOverAlpha];
    [self.lineWidthButton setBackgroundImage:lineWidthImage forState:UIControlStateNormal];
    
    //Sets up our slider with the variables needed to change opacity
    self.opacityLineWidthSlider.minimumValue = 0.0f;
    self.opacityLineWidthSlider.maximumValue = 1.0f;
    self.opacityLineWidthSlider.value = self.drawingView.opacity;
    [self sliderChanged:self.opacityLineWidthSlider];
    
    //What do we do now the opacity button has been pressed...
    if(button.tag == self.opacityLineWidthToolbar.tag) {
        //If we're already showing the opacity view, hide it
        [self hideOpacityLineWidth:button speed:0.075 completion:nil];
    }
    else if(!self.opacityLineWidthToolbar.hidden) {
        //If we're already showing another view, hide that then show the opacity view
        [self hideOpacityLineWidth:button speed:0.01 completion:^{
            [self showOpacity:button];
        }];
    }
    else {
        //If we're not showing another view, show the opacity view
        [self showOpacityLineWidth:button];
    }
}

- (IBAction)showLineWidth:(UIButton*)button {
    //Shows that we have selected line width
    button.tintColor = [UIColor redColor];
    self.opacityButton.tintColor = [UIColor blackColor];
    button.tag = -2;
    
    UIImage *buttonImage = [button.currentBackgroundImage add_tintedImageWithColor:button.tintColor style:ADDImageTintStyleOverAlpha];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    UIImage *opacityImage = [self.opacityButton.currentBackgroundImage add_tintedImageWithColor:self.opacityButton.tintColor style:ADDImageTintStyleOverAlpha];
    [self.opacityButton setBackgroundImage:opacityImage forState:UIControlStateNormal];
    
    //Sets up our slider with the variables needed to change line width
    self.opacityLineWidthSlider.minimumValue = 1.0f;
    self.opacityLineWidthSlider.maximumValue = 100.0f;
    self.opacityLineWidthSlider.value = self.drawingView.lineWidth;
    [self sliderChanged:self.opacityLineWidthSlider];
    
    //What do we do now the line width button has been pressed...
    if(button.tag == self.opacityLineWidthToolbar.tag && !self.opacityLineWidthToolbar.hidden) {
        //If we're already showing the line width view, hide it
        [self hideOpacityLineWidth:button speed:0.075f completion:nil];
    }
    else if(!self.opacityLineWidthToolbar.hidden) {
        //If we're already showing another view, hide that then show the line width view
        [self hideOpacityLineWidth:button speed:0.01 completion:^{
            [self showLineWidth:button];
        }];
    }
    else {
        //If we're not showing another view, show the line width view
        [self showOpacityLineWidth:button];
    }
}

- (void)showOpacityLineWidth:(UIButton*)button {
    if(!self.animating) {
        if(!self.shapeBackgroundToolbar.hidden) {
            //If we're showing the shapeBackgroundBar, hide it and then show the opacityLineWidth
            [self hideBackgroundShape:self.shapeBackgroundButton completion: ^{
                [self showOpacityLineWidth:button];
            }];
        }
        //Prepare our expandedOptions view for presentation
        self.animating = YES;
        self.opacityLineWidthToolbar.hidden = NO;
        self.opacityLineWidthToolbar.tag = button.tag;
        //Animates the view down from the moreOptions view
        [UIView animateKeyframesWithDuration:0.15 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
            CGRect frame = self.opacityLineWidthToolbar.frame;
            frame.origin.y = frame.size.height;
            self.opacityLineWidthToolbar.frame = frame;
        } completion:^(BOOL finished) {
            self.animating = NO;
        }];
    }
}

- (void)hideOpacityLineWidth:(UIButton*)button speed:(CGFloat)speed completion:(void(^)())completionBlock {
    if(!self.animating) {
        //Prepares our expandedOptions view for dismissal
        self.opacityButton.tintColor = [UIColor blackColor];
        self.lineWidthButton.tintColor = [UIColor blackColor];

        UIImage *opacityImage = [self.opacityButton.currentBackgroundImage add_tintedImageWithColor:self.opacityButton.tintColor style:ADDImageTintStyleOverAlpha];
        [self.opacityButton setBackgroundImage:opacityImage forState:UIControlStateNormal];
        
        UIImage *lineWidthImage = [self.lineWidthButton.currentBackgroundImage add_tintedImageWithColor:self.lineWidthButton.tintColor style:ADDImageTintStyleOverAlpha];
        [self.lineWidthButton setBackgroundImage:lineWidthImage forState:UIControlStateNormal];
        
        self.animating = YES;
        //Animates the view up to its original position
        [UIView animateKeyframesWithDuration:speed delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
            CGRect frame = self.opacityLineWidthToolbar.frame;
            frame.origin.y = 0;
            self.opacityLineWidthToolbar.frame = frame;
        } completion:^(BOOL finished) {
            self.animating = NO;
            self.opacityLineWidthToolbar.hidden = YES;
            self.opacityLineWidthToolbar.tag = 0;
            if(completionBlock) {
                completionBlock();
            }
        }];
    }
}

- (IBAction)showHideBackgroundShapeToolbar:(UIButton*)button {
    if(!self.animating) {
        //Prepare our expandedOptions view for presentation
        if(self.shapeBackgroundToolbar.hidden == NO) {
            //Hides the backgroundShapeBar
            self.animating = YES;
            button.enabled = NO;
            [self hideBackgroundShape:button completion:nil];
        }
        else {
            //Shows the backgroundShapeBar
            if(!self.opacityLineWidthToolbar.isHidden) {
                [self hideOpacityLineWidth:nil speed:0.075 completion:^{
                    self.animating = YES;
                    button.enabled = NO;
                    [self showBackgroundShape:button];
                }];
            }
            else {
                self.animating = YES;
                button.enabled = NO;
                [self showBackgroundShape:button];
            }
        }
    }
}

- (void)showBackgroundShape:(UIButton*)button {
    //Animates the view down from the moreOptions view
    self.shapeBackgroundToolbar.hidden = NO;
    [self.view bringSubviewToFront:self.shapeBackgroundToolbar];
    [self.view bringSubviewToFront:self.drawingToolbar];
    [button setBackgroundImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
    [UIView animateKeyframesWithDuration:0.15 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.shapeBackgroundToolbar.frame;
        frame.origin.y = frame.size.height;
        self.shapeBackgroundToolbar.frame = frame;
    } completion:^(BOOL finished) {
        self.animating = NO;
        button.enabled = YES;
    }];
}

- (void)hideBackgroundShape:(UIButton*)button completion:(void(^)())completionBlock {
    [button setBackgroundImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
    //Animates the view up from the moreOptions view
    [UIView animateKeyframesWithDuration:0.15 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.shapeBackgroundToolbar.frame;
        frame.origin.y = 0;
        self.shapeBackgroundToolbar.frame = frame;
    } completion:^(BOOL finished) {
        self.animating = NO;
        self.shapeBackgroundToolbar.hidden = YES;
        button.enabled = YES;
        if(completionBlock) {
            completionBlock();
        }
    }];
}

- (void)hideAll {
    //Sets up our drawingToolbar - hidden, -44 y origin and border
    self.drawingToolbar.hidden = YES;
    CGRect frame = self.drawingToolbar.frame;
    frame.origin.y = -frame.size.height;
    self.drawingToolbar.frame = frame;
    
    //Sets up our opacityLineWidthToolbar - hidden, 0 y origin and border
    self.opacityLineWidthToolbar.hidden = YES;
    CGRect opacityLineWidthFrame = self.opacityLineWidthToolbar.frame;
    opacityLineWidthFrame.origin.y = 0;
    self.opacityLineWidthToolbar.frame = opacityLineWidthFrame;
    
    //Sets up our shapeBackgroundToolbar - hidden, 0 y origin and border
    self.shapeBackgroundToolbar.hidden = YES;
    CGRect shapeBackgroundToolbar = self.shapeBackgroundToolbar.frame;
    shapeBackgroundToolbar.origin.y = 0;
    self.shapeBackgroundToolbar.frame = shapeBackgroundToolbar;
}

- (IBAction)showHideDrawingToolbar:(UIButton *)sender {
    if(!self.animating) {
        sender.enabled = NO;
        if (self.drawingToolbar.hidden) {
            //It's hidden, so let's show
            self.animating = YES;
            self.drawingToolbar.hidden = NO;
            [sender setBackgroundImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
            [UIView animateKeyframesWithDuration:0.2 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
                CGRect frame = self.drawingToolbar.frame;
                frame.origin.y = 0;
                self.drawingToolbar.frame = frame;
            } completion:^(BOOL finished) {
                self.animating = NO;
                sender.enabled = YES;
            }];
        }
        else {
            //It's showing, so let's hide it
            void(^Hide)() =  ^() {
                if(!self.opacityLineWidthToolbar.hidden) {
                    //If we're showing the opacityLineWidthToolbar, hide it THEN hide the whole bar
                    self.animating = YES;
                    
                    self.opacityButton.tintColor = [UIColor blackColor];
                    self.lineWidthButton.tintColor = [UIColor blackColor];
                    
                    UIImage *opacityImage = [self.opacityButton.currentBackgroundImage add_tintedImageWithColor:self.opacityButton.tintColor style:ADDImageTintStyleOverAlpha];
                    [self.opacityButton setBackgroundImage:opacityImage forState:UIControlStateNormal];
                    
                    UIImage *lineWidthImage = [self.lineWidthButton.currentBackgroundImage add_tintedImageWithColor:self.lineWidthButton.tintColor style:ADDImageTintStyleOverAlpha];
                    [self.lineWidthButton setBackgroundImage:lineWidthImage forState:UIControlStateNormal];
                    
                    [UIView animateWithDuration:0.125 animations:^{
                        CGRect frame = self.opacityLineWidthToolbar.frame;
                        frame.origin.y = 0;
                        self.opacityLineWidthToolbar.frame = frame;
                    } completion:^(BOOL finished) {
                        self.opacityLineWidthToolbar.hidden = YES;
                        self.animating = NO;
                        [self showHideDrawingToolbar:sender];
                    }];
                }
                else if(!self.shapeBackgroundToolbar.hidden) {
                    //If we're showing the shapeBackgroundToolbar, hit it THEN the whole bar
                    self.animating = YES;
                    [self.shapeBackgroundButton setBackgroundImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
                    [UIView animateWithDuration:0.125 animations:^{
                        CGRect frame = self.shapeBackgroundToolbar.frame;
                        frame.origin.y = 0;
                        self.shapeBackgroundToolbar.frame = frame;
                    } completion:^(BOOL finished) {
                        self.shapeBackgroundToolbar.hidden = YES;
                        self.animating = NO;
                        [self showHideDrawingToolbar:sender];
                    }];
                }
                else {
                    //Just hide it normally!
                    [self.shapeBackgroundButton setBackgroundImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
                    self.animating = YES;
                    [sender setBackgroundImage:[UIImage imageNamed:@"down.png"] forState:UIControlStateNormal];
                    [UIView animateKeyframesWithDuration:0.15 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
                        CGRect frame = self.drawingToolbar.frame;
                        frame.origin.y = -frame.size.height;
                        self.drawingToolbar.frame = frame;
                    } completion:^(BOOL finished) {
                        self.animating = NO;
                        sender.enabled = YES;
                        self.drawingToolbar.hidden = YES;
                    }];
                }
            };
            Hide();
        }
    }
}

@end
