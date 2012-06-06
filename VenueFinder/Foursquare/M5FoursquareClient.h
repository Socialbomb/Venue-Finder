//  M5FoursquareClient.h
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import <MapKit/MapKit.h>
#import "AFHTTPClient.h"
#import "M5VenueCategory.h"
#import "M5Venue.h"

// Interface to foursquare™'s API.

@interface M5FoursquareClient : AFHTTPClient

+(M5FoursquareClient *)sharedClient;

// The date at which the venue categories were last fetched, or nil if they haven't been retrieved yet.
@property (nonatomic, strong, readonly) NSDate *cachedCategoriesDate;

// The current list of venue categories (M5VenueCategory objects), or nil if they haven't been
// retrieved yet. Call -getVenueCategoriesIgnoringCache:completion:failure: to load the categories
// from Foursquare's API or the cache.
@property (nonatomic, strong, readonly) NSArray *venueCategories;

// Looks up a venue category by ID. Returns nil if there is no matching category.
-(M5VenueCategory *)venueCategoryForID:(NSString *)venueCategoryID;

// Loads the list of venue categories, either from the API or cache.
// If ignoreCache is YES, any cache is ignored. The API will be consulted and the cache will
// be updated upon completion. If ignoreCache is NO and there is a cached list of venues, it
// will be loaded.
// At the time the completion block is called, the venueCategories property will be set.
-(void)getVenueCategoriesIgnoringCache:(BOOL)ignoreCache
                            completion:(void (^)(NSArray *categories))completion
                               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

// Returns YES if the given map region is of a size that can be searched using 
// -getVenuesOfCategory:inMapRegion:completion:failure:.
// The foursquare™ docs say the max searchable region is approximately 10,000 sq km.
-(BOOL)mapRegionIsOfSearchableArea:(MKCoordinateRegion)mapRegion;

// Returns a maximum of 50 M5Venues of the given category or its subcategories in the given map region.
// The resulting objects are abbreviated; not all fields will be returned (see the docs here:
// https://developer.foursquare.com/docs/responses/venue). To get all fields associated with a venue,
// use -getVenueWithID:completion:failure:.
-(void)getVenuesOfCategory:(NSString *)categoryID
               inMapRegion:(MKCoordinateRegion)mapRegion
                completion:(void (^)(NSArray *venues))completion
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

// Returns a complete M5Venue object for the given venue ID.
// Unlike the venue objects returned by the -getVenuesOfCategory: search, this object will
// have all available fields set.
-(void)getVenueWithID:(NSString *)venueID
           completion:(void (^)(M5Venue *venue))completion
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

// Aborts a call to -getVenueWithID:completion:failure: with the given ID.
// The associated failure block passed to -getVenueWithID: will not be called.
-(void)cancelGetOfVenueID:(NSString *)venueID;

@end
