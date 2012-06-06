//  M5PlacemarkAnnotation.m
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import "M5PlacemarkAnnotation.h"
#import "CLPlacemark+M5Utils.h"

@interface M5PlacemarkAnnotation ()

@property (nonatomic, strong, readwrite) CLPlacemark *placemark;

// Re-define properties from MKAnnotation to be readwrite,
// so we can assign to them in order to implement the protocol.
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *subtitle;
@property (nonatomic, assign, readwrite) CLLocationCoordinate2D coordinate;

@end


@implementation M5PlacemarkAnnotation

@synthesize placemark = _placemark;
@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize coordinate = _coordinate;

-(id)initWithPlacemark:(CLPlacemark *)placemark
{
    self = [super init];
    if(self) {
        self.placemark = placemark;
        
        self.title = self.placemark.friendlyTitle;
        self.subtitle = self.placemark.friendlySubtitle;
        self.coordinate = self.placemark.location.coordinate;
    }
    
    return self;
}

@end
