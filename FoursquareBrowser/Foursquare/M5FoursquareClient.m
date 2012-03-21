//
//  M5FoursquareClient.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "M5FoursquareClient.h"
#import "AFJSONRequestOperation.h"

@implementation M5FoursquareClient

+(M5FoursquareClient *)sharedClient
{
    static dispatch_once_t onceToken;
    static M5FoursquareClient *staticSharedClient;
    
    dispatch_once(&onceToken, ^{
        staticSharedClient = [[M5FoursquareClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.foursquare.com/v2/"]];
    });
    
    return staticSharedClient;
}

-(id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if(self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
    }
    
    return self;
}

-(NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    // Throw in version and auth stuff, if it wasn't in there already
    NSMutableDictionary *params = parameters ? [parameters mutableCopy] : [NSMutableDictionary dictionary];
    
    if(![params objectForKey:@"v"])
        [params setObject:@"20120321" forKey:@"v"];
    
    if(![params objectForKey:@"client_id"])
        [params setObject:M5FoursquareAppID forKey:@"client_id"];
    
    if(![params objectForKey:@"client_secret"])
        [params setObject:M5FoursquareAppSecret forKey:@"client_secret"];
    
    parameters = params;
    
    NSMutableURLRequest *req = [super requestWithMethod:method path:path parameters:parameters];
    req.timeoutInterval = M5FoursquareAPITimeout;
    return req;
}

#pragma mark - API calls

-(void)getVenueCategoriesWithCompletion:(void (^)(NSArray *))completion failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self getPath:@"venues/categories" parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSArray *categoryDicts = [[JSON objectForKey:@"response"] objectForKey:@"categories"];

        NSMutableArray *categories = [NSMutableArray arrayWithCapacity:categoryDicts.count];
        for(NSDictionary *categoryDict in categoryDicts)
            [categories addObject:[[M5VenueCategory alloc] initWithDictionary:categoryDict]];
        
        if(completion)
            completion(categories);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failure)
            failure(operation, error);
    }];
}

-(void)getVenuesOfCategory:(NSString *)categoryID inMapRegion:(MKCoordinateRegion)mapRegion completion:(void (^)(NSArray *))completion failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    CLLocationCoordinate2D northEastCorner, southWestCorner;
    northEastCorner.latitude  = mapRegion.center.latitude  + (mapRegion.span.latitudeDelta  / 2.0);
    northEastCorner.longitude = mapRegion.center.longitude + (mapRegion.span.longitudeDelta / 2.0);
    southWestCorner.latitude  = mapRegion.center.latitude  - (mapRegion.span.latitudeDelta  / 2.0);
    southWestCorner.longitude = mapRegion.center.longitude - (mapRegion.span.longitudeDelta / 2.0);
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"browse", @"intent", 
                                   @"50", @"limit",
                                   [NSString stringWithFormat:@"%.6f,%.6f", northEastCorner.latitude, northEastCorner.longitude], @"ne",
                                   [NSString stringWithFormat:@"%.6f,%.6f", southWestCorner.latitude, southWestCorner.longitude], @"sw",
                                   nil];
    
    if(categoryID)
        [params setObject:categoryID forKey:@"categoryId"];
    
    [self getPath:@"venues/search" parameters:params success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSArray *venueDicts = [[JSON objectForKey:@"response"] objectForKey:@"venues"];
        
        NSMutableArray *venues = [NSMutableArray arrayWithCapacity:venueDicts.count];
        for(NSDictionary *venueDict in venueDicts)
            [venues addObject:[[M5Venue alloc] initWithDictionary:venueDict]];
        
        if(completion)
            completion(venues);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failure)
            failure(operation, error);
    }];
}

@end
