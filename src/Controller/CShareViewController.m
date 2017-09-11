//
//  CShareViewController.m
//  canvas
//
//  Created by Hugh Bellamy on 25/01/2014.
//  Copyright (c) 2014 Hugh Bellamy. All rights reserved.
//

@import Social;

#import "CShareViewController.h"

#import "CModel.h"
#import "MBProgressHUD.h"

@interface CShareViewController ()

@end

@implementation CShareViewController

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [CModel writeCanUseMoreBrushes:YES];
}

- (IBAction)showSupportAndSuggestions:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://hughbellamyapps.wufoo.com/forms/canvas-support-and-suggestions/"];
    [[UIApplication sharedApplication]openURL:url options:@{} completionHandler:nil];
}

- (IBAction)reviewOnAppStore:(id)sender {
    SKStoreProductViewController *storeKitProductViewController = [[SKStoreProductViewController alloc]init];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Loading";

    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    
    storeKitProductViewController.delegate = self;
    [storeKitProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @"777551805"} completionBlock:^(BOOL result, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
        }
        else {
            [self.controller presentViewController:storeKitProductViewController animated:YES completion:^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
            }];
        }
    }];
}

- (IBAction)shareOnTwitter:(id)sender {
    [self presentSocialSheet:SLServiceTypeTwitter];
}

- (IBAction)shareOnFacebook:(id)sender {
    [self presentSocialSheet:SLServiceTypeFacebook];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self.controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if(error) {
        NSLog(@"%@", error);
    }
    
    [self.controller dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)shareOnEmail:(id)sender {
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@"Canvas"];
    
    NSString *content = @"Canvas is a new app on iOS devices. It is fully customizable and has loads of features not found on any other apps. Try it out <a href = 'http://bit.ly/1aVgU62'>here </a> ";
    
    [picker setMessageBody:content isHTML:YES];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Loading";

    [self.controller presentViewController:picker animated:YES completion:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

- (IBAction)shareOnMessages:(id)sender {
    if([MFMessageComposeViewController canSendText]) {
        NSString *content = @"Canvas is a new app on iOS devices. It is fully customizable and has loads of features not found on any other apps. Try it out here: http://bit.ly/1aVgU62";
        
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        controller.body = content;
        controller.recipients = nil;
        controller.messageComposeDelegate = self;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = @"Loading";
        
        [self.controller presentViewController:controller animated:YES completion:^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Your device cannot send messages" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)presentSocialSheet:(NSString*)serviceType {
    SLComposeViewController *sheet = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    [sheet setInitialText:@"Canvas is a great new drawing app with a ton of features. Download it here: http://bit.ly/1aVgU62"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Loading";
    [self.controller presentViewController:sheet animated:YES completion:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}
@end
