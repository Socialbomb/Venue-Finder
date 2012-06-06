//  UIViewController+ProgressHUD.m
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import "UIViewController+MBProgressHUD.h"

@implementation UIViewController (MBProgressHUD)

-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details dimScreen:(BOOL)dimScreen
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = text;
    hud.detailsLabelText = details;
    hud.dimBackground = dimScreen;
    
    return hud;
}

-(MBProgressHUD *)showHUDFromViewWithText:(NSString *)text details:(NSString *)details
{
    return [self showHUDFromViewWithText:text details:details dimScreen:NO];
}

-(void)hideAllHUDsFromView
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

@end
