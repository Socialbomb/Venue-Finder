//
//  M5FoursquareClient.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AFHTTPClient.h"
#import "M5VenueCategory.h"
#import "M5Venue.h"
#import <MapKit/MapKit.h>

@interface M5FoursquareClient : AFHTTPClient

+(M5FoursquareClient *)sharedClient;

@property (nonatomic, strong, readonly) NSArray *venueCategories;
-(M5VenueCategory *)venueCategoryForID:(NSString *)venueCategoryID;

-(void)getVenueCategoriesWithCompletion:(void (^)(NSArray *categories))completion
                                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(BOOL)mapRegionIsOfSearchableArea:(MKCoordinateRegion)mapRegion;

-(void)getVenuesOfCategory:(NSString *)categoryID
               inMapRegion:(MKCoordinateRegion)mapRegion
                completion:(void (^)(NSArray *venues))completion
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void)getVenueWithID:(NSString *)venueID
           completion:(void (^)(M5Venue *venue))completion
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void)cancelGetOfVenueID:(NSString *)venueID;

@end
