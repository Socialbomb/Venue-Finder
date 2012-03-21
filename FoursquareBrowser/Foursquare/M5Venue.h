//
//  M5Venue.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface M5Venue : NSObject <MKAnnotation>

@property (nonatomic, strong, readonly) NSString *_id;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) CLLocationCoordinate2D coordinate;

-(id)initWithDictionary:(NSDictionary *)dictionary;

@end
