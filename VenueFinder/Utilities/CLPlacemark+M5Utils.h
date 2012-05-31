//
//  CLPlacemark+Utils.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLPlacemark (M5Utils)

@property (nonatomic, readonly) NSString *streetAddress;
@property (nonatomic, readonly) NSString *friendlyTitle;
@property (nonatomic, readonly) NSString *friendlySubtitle;

@end
