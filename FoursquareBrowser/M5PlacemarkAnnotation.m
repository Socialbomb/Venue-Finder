//
//  M5PlacemarkAnnotation.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "M5PlacemarkAnnotation.h"
#import "CLPlacemark+Utils.h"

@interface M5PlacemarkAnnotation ()

@property (nonatomic, strong, readwrite) CLPlacemark *placemark;

@end


@implementation M5PlacemarkAnnotation

@synthesize placemark;

-(id)initWithPlacemark:(CLPlacemark *)thePlacemark
{
    self = [super init];
    if(self) {
        self.placemark = thePlacemark;
        
        if(placemark.name || placemark.streetAddress) {
            theTitle = placemark.name ? placemark.name : placemark.streetAddress;
            theSubtitle = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.ISOcountryCode];
        }
        else if(placemark.locality) {
            theTitle = [NSString stringWithFormat:@"%@", placemark.locality];
            theSubtitle = [NSString stringWithFormat:@"%@, %@", placemark.administrativeArea, placemark.ISOcountryCode];
        }
        else {
            theTitle = placemark.administrativeArea;
            theSubtitle = placemark.ISOcountryCode;
        }
    }
    
    return self;
}

-(CLLocationCoordinate2D)coordinate
{
    return self.placemark.location.coordinate;
}

-(NSString *)title
{
    return theTitle;
}

-(NSString *)subtitle
{
    return theSubtitle;
}

@end
