//
//  M5PlacemarkAnnotation.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import "M5PlacemarkAnnotation.h"
#import "CLPlacemark+M5Utils.h"

@interface M5PlacemarkAnnotation ()

@property (nonatomic, strong, readwrite) CLPlacemark *placemark;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *subtitle;

@end


@implementation M5PlacemarkAnnotation

@synthesize placemark;
@synthesize title;
@synthesize subtitle;

-(id)initWithPlacemark:(CLPlacemark *)thePlacemark
{
    self = [super init];
    if(self) {
        self.placemark = thePlacemark;
        
        self.title = placemark.friendlyTitle;
        self.subtitle = placemark.friendlySubtitle;
    }
    
    return self;
}

-(CLLocationCoordinate2D)coordinate
{
    return self.placemark.location.coordinate;
}

@end
