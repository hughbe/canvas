//
//  CCell.m
//  canvas
//
//  Created by Hugh Bellamy on 12/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CCell.h"

#import <MediaPlayer/MediaPlayer.h>

#import "UIImage+Additions.h"
#import "UIView+Borders.h"
#import "CDrawingView.h"

@interface CCell ()

@property (nonatomic, strong) UIView *largeViewing;
@property (nonatomic, strong) UIImageView *plusImageView;

@property (nonatomic, strong) UIImageView *drawing;

@property (nonatomic, strong) MPMoviePlayerController *player;

@property (nonatomic, assign) BOOL animating;

@end

@implementation CCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.optionsView addBottomBorderWithHeight:0.75 andColor:[UIColor lightGrayColor]];
    [self.titleView addBottomBorderWithHeight:0.75 andColor:[UIColor lightGrayColor]];
    [self.bottomView addBottomBorderWithHeight:0.75 andColor:[UIColor lightGrayColor]];
    
    
    self.layer.cornerRadius = 10.0f;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(expand:)]];
    
    for(UIButton *button in [self.optionsView.subviews copy]) {
        UIImage *tintedImage = [button.currentBackgroundImage add_tintedImageWithColor:[UIColor blackColor] style:ADDImageTintStyleOverAlpha];
        [button setBackgroundImage:tintedImage forState:UIControlStateNormal];
    }
    
    [[NSNotificationCenter defaultCenter]addObserverForName:MPMoviePlayerDidEnterFullscreenNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self.player setFullscreen:NO animated:NO];
        [self.player stop];
        [self.drawing removeFromSuperview];
        [self hide:nil];
    }];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if([UIScreen mainScreen].bounds.size.height < 568) {
            CGRect rect = self.imageView.frame;
            rect.size.width = 250;
            rect.size.height = 325;
            rect.origin = self.imageView.frame.origin;
            self.imageView.frame = rect;
            
            CGRect rect2 = self.bottomView.frame;
            rect2.origin.y = self.imageView.frame.origin.y + self.imageView.frame.size.height;
            self.bottomView.frame = rect2;
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (UIImageView *)plusImageView {
    //Lazily instantiates our newDrawing imageView
    if(!_plusImageView) {
        UIImage *image = [UIImage imageNamed:@"New Drawing"];
        _plusImageView = [[UIImageView alloc]initWithImage:image];
        CGRect frame = self.frame;
        frame.origin = CGPointZero;
        _plusImageView.frame = frame;
    }
    return _plusImageView;
}

- (void)showNew {
    //If we're not showing the newDrawing image...
    [self hideAll];
    if(!_plusImageView.superview) {
        //Shows it and then hides all the other UI components
        [self addSubview:self.plusImageView];
    }
}

- (void)hideAll {
    self.titleView.hidden = YES;
    self.titleLabel.hidden = YES;
    
    self.imageView.hidden = YES;
    
    self.bottomView.hidden = YES;
    self.dateLabel.hidden = YES;
    
    self.optionsView.hidden = YES;
}

- (void)hideNew {
    //If we're showing the newDrawing image...
    self.layer.borderWidth = 2.0;
    self.titleView.hidden = NO;
    self.titleLabel.hidden = NO;
    
    self.imageView.hidden = NO;
    
    self.bottomView.hidden = NO;
    self.dateLabel.hidden = NO;
    
    self.optionsView.hidden = NO;
    //Sets up the large viewing of our drawing
    CGRect frame = self.optionsView.frame;
    frame.origin.x = self.frame.size.width - 44;
    frame.origin.y = 0;
    self.optionsView.frame = frame;
    
    if(_plusImageView) {
        //Hides it and then unhides all the other UI components
        [self.plusImageView removeFromSuperview];
        
        self.plusImageView = nil;
    }
}

- (IBAction)showHideOptions:(UIButton*)sender {
    if(!self.animating) {
        //Starts animating
        self.animating = YES;
        sender.enabled = NO;
        __block CGRect frame = self.optionsView.frame;
        CGFloat x1 = 0;
        CGFloat x2 = 0;
        CGFloat duration = 0.35;
        
        if(frame.origin.x == 0) {
            //Hides the optionsView
            x2 = self.frame.size.width - 44;
            x1 = x2 + 15;
            duration = 0.2;
            
            UIImage *tintedImage = [[UIImage imageNamed:@"reveal"]add_tintedImageWithColor:[UIColor blackColor] style:ADDImageTintStyleOverAlpha];
            [sender setBackgroundImage:tintedImage forState:UIControlStateNormal];
        }
        else {
            x1 = -15;
            //Show the optionsView
            UIImage *tintedImage = [[UIImage imageNamed:@"hide"]add_tintedImageWithColor:[UIColor blackColor] style:ADDImageTintStyleOverAlpha];
            [sender setBackgroundImage:tintedImage forState:UIControlStateNormal];
        }
        //Animates the showing or hiding of the optionsView
        [UIView animateKeyframesWithDuration:duration delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
            frame.origin.x = x1;
            self.optionsView.frame = frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25 animations:^{
                frame.origin.x = x2;
                self.optionsView.frame = frame;
            } completion:^(BOOL didFinish) {
                self.animating = NO;
                sender.enabled = YES;
            }];
        }];
    }
}

- (IBAction)expand:(id)sender {
    [self.delegate expandedDrawing:self];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    //Creates a copy of our imageView from the same location
    self.imageView.hidden = YES;
    
    if(self.videoPath.length && ![self.videoPath isEqualToString:@"nil"]) {
        self.player = [[MPMoviePlayerController alloc]initWithContentURL:[NSURL fileURLWithPath:self.videoPath]];
        self.largeViewing = self.player.view;
        self.largeViewing.frame = [window convertRect:self.imageView.frame fromView:self];
    }
    else {
        self.player = nil;
        [self.drawing removeFromSuperview];
        self.largeViewing = [[UIImageView alloc]initWithImage:self.imageView.image];
    }
    
    self.largeViewing.frame = [window convertRect:self.imageView.frame fromView:self];
    self.largeViewing.contentMode = UIViewContentModeScaleAspectFit;
    self.largeViewing.userInteractionEnabled = YES;
    
    //...Then shows it originating from our origin. It can be closed by a swipe action or a pinch action
    UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hide:)];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionUp;
    [self.largeViewing addGestureRecognizer:swipeGestureRecognizer];
    
    [self.largeViewing addGestureRecognizer:[[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(hide:)]];
    [window addSubview:self.largeViewing];
    
    //Opening an image
    self.largeViewing.layer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0].CGColor;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.largeViewing.frame = window.bounds;
        self.largeViewing.layer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0].CGColor;
    } completion:^(BOOL finished) {
        if(self.player) {
            self.drawing = [[UIImageView alloc]initWithImage:[self drawBitmap]];
            self.drawing.frame = self.player.view.frame;
            self.drawing.userInteractionEnabled = NO;
            [self.window addSubview:self.drawing];
            [self.player play];
        }
    }];
}

- (UIImage*)drawBitmap {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0);
    //Creates a copy of our current pathArray to prevent mutability crash
    for (UIBezierPath *currentPath in [self.pathArray copy]) {
        //Loops through our paths and adds them to our view
        [currentPath.color setStroke];
        //But are we erasing...
        if(currentPath.color == [UIColor clearColor]) {
            
            //Yes, so clear everything
            [currentPath strokeWithBlendMode:kCGBlendModeCopy alpha:1.0f];
        }
        //Shapes are filled in
        else if(currentPath.type == CBrushTypeShape) {
            [currentPath.color setFill];
            [currentPath fillWithBlendMode:currentPath.blendMode alpha:currentPath.opacity];
        }
        else {
            [currentPath.color setStroke];
            [currentPath strokeWithBlendMode:currentPath.blendMode alpha:currentPath.opacity];
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (IBAction)edit:(id)sender {
    //Defers the action to the controller to edit us
    [self.delegate editDrawing:self];
}

- (IBAction)delete:(id)sender {
    //Defers the action to the controller to delete us
    [self.delegate deleteDrawing:self];
    
}
- (IBAction)share:(id)sender {
    //Defers the action to the controller to share us
    [self.delegate shareDrawing:self];
}

- (void)hide:(UIGestureRecognizer*)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateEnded | gestureRecognizer.state == UIGestureRecognizerStateFailed || gestureRecognizer.state == UIGestureRecognizerStateCancelled || gestureRecognizer == nil) {
        //Animates the hiding of the largeViewing imageView back to the original origin and size
        self.imageView.hidden = NO;
        
        if(self.player) {
            [self.player stop];
        }
        [UIView animateWithDuration:0.15 animations:^{
            self.largeViewing.frame = [[UIApplication sharedApplication].keyWindow convertRect:self.imageView.frame fromView:self];
            self.largeViewing.layer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0].CGColor;
        } completion:^(BOOL finished) {
            self.player = nil;
            [self.drawing removeFromSuperview];
            self.drawing = nil;
            
            [self.largeViewing removeFromSuperview];
            self.largeViewing = nil;
        }];
    }
}

@end
