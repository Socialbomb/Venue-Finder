//
//  M5Venue.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "M5VenueCategory.h"

@interface M5VenueLocation : NSObject

@property (nonatomic, strong, readonly) NSString *streetAddress;
@property (nonatomic, strong, readonly) NSString *crossStreet;
@property (nonatomic, strong, readonly) NSString *city;
@property (nonatomic, strong, readonly) NSString *state;
@property (nonatomic, strong, readonly) NSString *postalCode;
@property (nonatomic, strong, readonly) NSString *country;

@property (nonatomic, assign, readonly) CLLocationCoordinate2D coordinate;

-(id)initWithDictionary:(NSDictionary *)dictionary;

@end


@interface M5VenueStats : NSObject

@property (nonatomic, assign, readonly) uint totalCheckins;
@property (nonatomic, assign, readonly) uint totalUsers;
@property (nonatomic, assign, readonly) uint totalTips;
@property (nonatomic, assign, readonly) uint currentCheckinCount;

-(id)initWithDictionary:(NSDictionary *)dictionary;

@end


@interface M5Venue : NSObject <MKAnnotation>

@property (nonatomic, strong, readonly) NSString *_id;
@property (nonatomic, strong, readonly) NSURL *venueURL;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *venueDescription;
@property (nonatomic, strong, readonly) NSDate *createdAt;
@property (nonatomic, strong, readonly) M5VenueLocation *location;

@property (nonatomic, strong, readonly) NSString *twitterHandle;
@property (nonatomic, strong, readonly) NSString *phoneNumber;
@property (nonatomic, strong, readonly) NSString *formattedPhoneNumber;
@property (nonatomic, strong, readonly) NSURL *websiteURL;
@property (nonatomic, assign, readonly) BOOL verified;

@property (nonatomic, strong, readonly) M5VenueStats *stats;

@property (nonatomic, strong, readonly) NSArray *tags;
@property (nonatomic, strong, readonly) NSArray *categories;  // The primary category is always first

-(id)initWithDictionary:(NSDictionary *)dictionary;

@end
