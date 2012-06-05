//
//  UIViewController+ProgressHUD.m
//  Venue Finder
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

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
