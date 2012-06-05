//
//  M5PlacemarkAnnotation.h
//  Venue Finder
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

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
