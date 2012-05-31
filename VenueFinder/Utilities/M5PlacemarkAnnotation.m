//
//  M5PlacemarkAnnotation.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
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
        
        _title = placemark.friendlyTitle;
        _subtitle = placemark.friendlySubtitle;
    }
    
    return self;
}

-(CLLocationCoordinate2D)coordinate
{
    return self.placemark.location.coordinate;
}

-(NSString *)title
{
    return _title;
}

-(NSString *)subtitle
{
    return _subtitle;
}

@end
