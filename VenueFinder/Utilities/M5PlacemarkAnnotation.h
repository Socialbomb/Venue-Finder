//  M5PlacemarkAnnotation.h
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

// A map annotation to represent a CLPlacemark.
// Uses the friendlyTitle/friendlySubtitle methods from CLPlacemark+M5Utils for
// MKAnnotation's title and subtitle.

@interface M5PlacemarkAnnotation : NSObject <MKAnnotation>

@property (nonatomic, strong, readonly) CLPlacemark *placemark;

-(id)initWithPlacemark:(CLPlacemark *)placemark;

@end
