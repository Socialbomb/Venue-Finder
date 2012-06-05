//
//  M5AppDelegate.m
//  Venue Finder
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import "M5AppDelegate.h"

#import "M5ViewController.h"

@implementation M5AppDelegate

@synthesize window = _window;
@synthesize navController = _navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    M5ViewController *rootViewController = [[M5ViewController alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    self.navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];
    
#ifdef TESTFLIGHT
    #ifdef TESTFLIGHT_USE_UDID
        [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    #endif
    
    [TestFlight takeOff:M5TestFlightTeamToken];
#endif
    
    return YES;
}

@end
