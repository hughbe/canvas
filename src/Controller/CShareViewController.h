//
//  CShareViewController.h
//  canvas
//
//  Created by Hugh Bellamy on 25/01/2014.
//  Copyright (c) 2014 Hugh Bellamy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import <MessageUI/MessageUI.h>

@interface CShareViewController : UIViewController<SKStoreProductViewControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property (strong, nonatomic) UIViewController *controller;
@end
