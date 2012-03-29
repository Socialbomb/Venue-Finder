//
//  M5PlacemarkAnnotation.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface M5PlacemarkAnnotation : NSObject <MKAnnotation> {
    NSString *theTitle;
    NSString *theSubtitle;
}

@property (nonatomic, strong, readonly) CLPlacemark *placemark;

-(id)initWithPlacemark:(CLPlacemark *)thePlacemark;

@end
