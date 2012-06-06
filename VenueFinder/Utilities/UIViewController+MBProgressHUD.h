//  UIViewController+ProgressHUD.h
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

// Convenience methods to present MBProgressHUD views from view controllers.

@interface UIViewController (MBProgressHUD)

-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details;
-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details dimScreen:(BOOL)dimScreen;

-(void)hideAllHUDsFromView;

@end
