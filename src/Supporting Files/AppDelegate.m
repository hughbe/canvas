//
//  AppDelegate.m
//  canvas
//
//  Created by Hugh Bellamy on 09/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "AppDelegate.h"
#import "WYPopoverController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setFont:[UIFont fontWithName:@"Arial" size:14.0]];

    UIColor *greenColor = [UIColor colorWithRed:26.f / 255.f green:188.f / 255.f blue:156.f / 255.f alpha:1];
    WYPopoverBackgroundView *popoverAppearance = [WYPopoverBackgroundView appearance];

    [popoverAppearance setOuterCornerRadius:4];
    [popoverAppearance setOuterShadowBlurRadius:0];
    [popoverAppearance setOuterShadowColor:[UIColor clearColor]];
    [popoverAppearance setOuterShadowOffset:CGSizeMake(0, 0)];

    [popoverAppearance setGlossShadowColor:[UIColor clearColor]];
    [popoverAppearance setGlossShadowOffset:CGSizeMake(0, 0)];

    [popoverAppearance setBorderWidth:3];
    [popoverAppearance setArrowHeight:10];
    [popoverAppearance setArrowBase:20];

    [popoverAppearance setInnerCornerRadius:4];
    [popoverAppearance setInnerShadowBlurRadius:0];
    [popoverAppearance setInnerShadowColor:[UIColor clearColor]];
    [popoverAppearance setInnerShadowOffset:CGSizeMake(0, 0)];

    [popoverAppearance setFillTopColor:greenColor];
    [popoverAppearance setFillBottomColor:greenColor];
    [popoverAppearance setOuterStrokeColor:greenColor];
    [popoverAppearance setInnerStrokeColor:greenColor];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
