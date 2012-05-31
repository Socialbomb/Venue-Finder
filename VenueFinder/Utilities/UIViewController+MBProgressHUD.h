//
//  UIViewController+ProgressHUD.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface UIViewController (MBProgressHUD)

-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text;
-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text dimScreen:(BOOL)dimScreen;

-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details;
-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details dimScreen:(BOOL)dimScreen;

-(void)hideAllHUDsFromView;

@end
