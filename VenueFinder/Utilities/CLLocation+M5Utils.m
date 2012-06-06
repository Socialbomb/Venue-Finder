//  CLLocation+Utils.m
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import "CLLocation+M5Utils.h"

@implementation CLLocation (M5Utils)

+(CLLocationDistance)distanceFromCoordinate:(CLLocationCoordinate2D)fromCoord toCoordinate:(CLLocationCoordinate2D)toCoord
{
    CLLocation *fromLoc = [[CLLocation alloc] initWithLatitude:fromCoord.latitude longitude:fromCoord.longitude];
    CLLocation *toLoc = [[CLLocation alloc] initWithLatitude:toCoord.latitude longitude:toCoord.longitude];
    
    return [toLoc distanceFromLocation:fromLoc];
}

@end
