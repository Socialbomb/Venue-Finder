//  CLLocation+Utils.h
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (M5Utils)

// Convenience method to get the distance between two CLLocationCoordinate2D objects.
// Creates two CLLocation objects and uses -distanceFromLocation: to calculate
// the distance.
+(CLLocationDistance)distanceFromCoordinate:(CLLocationCoordinate2D)fromCoord toCoordinate:(CLLocationCoordinate2D)toCoord;

@end
