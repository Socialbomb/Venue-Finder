//
//  M5PlacemarkAnnotation.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface M5PlacemarkAnnotation : NSObject <MKAnnotation> {
    NSString *_title;
    NSString *_subtitle;
}

@property (nonatomic, strong, readonly) CLPlacemark *placemark;

-(id)initWithPlacemark:(CLPlacemark *)thePlacemark;

@end
