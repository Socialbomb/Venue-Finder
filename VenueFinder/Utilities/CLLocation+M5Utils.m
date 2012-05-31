//
//  CLLocation+Utils.m
//  VenueFinder
//
//  Created by Tim Clem on 5/31/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import "CLLocation+M5Utils.h"

@implementation CLLocation (M5Utils)

+(CLLocationDistance)distanceFromCoordinate:(CLLocationCoordinate2D)fromCoord toCoordinate:(CLLocationCoordinate2D)toCoord
{
    CLLocation *fromLoc = [[CLLocation alloc] initWithLatitude:fromCoord.latitude longitude:fromCoord.longitude];
    CLLocation *toLoc = [[CLLocation alloc] initWithLatitude:toCoord.latitude longitude:toCoord.longitude];
    
    return [toLoc distanceFromLocation:fromLoc];
}

@end
