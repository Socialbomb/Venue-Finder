//
//  UIViewController+ProgressHUD.h
//  Venue Finder
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

// Convenience methods to present MBProgressHUD views from view controllers.

@interface UIViewController (MBProgressHUD)

-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details;
-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details dimScreen:(BOOL)dimScreen;

-(void)hideAllHUDsFromView;

@end
