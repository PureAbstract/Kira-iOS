//
//  KiraAppDelegate.m
//  Kira
//
//  Created by Andy Sawyer on 13/06/2011.
//  Copyright 2011 Andy Sawyer. All rights reserved.
//

#import "KiraAppDelegate.h"
#import <Foundation/Foundation.h>

@implementation KiraAppDelegate

#pragma mark -
#pragma mark Properties
@synthesize window;
@synthesize navigationController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Add the navigation controller's view to the window and display.
    [self.window addSubview:navigationController.view];
    [self.window makeKeyAndVisible];
    return YES;
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [navigationController release];
    [window release];
    [super dealloc];
}


@end

