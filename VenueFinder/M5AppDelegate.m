//  M5AppDelegate.m
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

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
    
    // Update the version number in our preferences, which is displayed in the settings bundle.
    // This is a little odd, since if the user launches the settings bundle before launching
    // the app, the version number will be missing or outdated. But that's probably not a case
    // worth worrying about.
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    NSString *friendlyVersion = [NSString stringWithFormat:@"%@ (%@)", version, build];
    [[NSUserDefaults standardUserDefaults] setObject:friendlyVersion forKey:@"M5AppVersion"];
    
    return YES;
}

@end
