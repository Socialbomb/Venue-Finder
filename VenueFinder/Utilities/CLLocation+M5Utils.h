//
//  CLLocation+Utils.h
//  VenueFinder
//
//  Created by Tim Clem on 5/31/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (M5Utils)

// Convenience method to get the distance between two CLLocationCoordinate2D objects.
// Creates two CLLocation objects and uses -distanceFromLocation: to calculate
// the distance.
+(CLLocationDistance)distanceFromCoordinate:(CLLocationCoordinate2D)fromCoord toCoordinate:(CLLocationCoordinate2D)toCoord;

@end
