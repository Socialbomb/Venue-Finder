//
//  M5FoursquareClient.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "M5FoursquareClient.h"
#import "AFJSONRequestOperation.h"

@interface M5FoursquareClient ()

@property (nonatomic, strong, readwrite) NSArray *venueCategories;

-(void)addToFlatCategories:(NSArray *)someCategories accumulator:(NSMutableArray *)flatCategories;
-(NSArray *)flattenCategories:(NSArray *)theCategories;

@end


@implementation M5FoursquareClient

@synthesize venueCategories;

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
        
        self.venueCategories = [self flattenCategories:categories];
        
        if(completion)
            completion(self.venueCategories);
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

-(void)getVenueWithID:(NSString *)venueID completion:(void (^)(M5Venue *))completion failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"venues/%@", venueID];
    [self getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSDictionary *venueDict = [[JSON objectForKey:@"response"] objectForKey:@"venue"];
        
        M5Venue *venue = [[M5Venue alloc] initWithDictionary:venueDict];
        if(completion)
            completion(venue);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failure)
            failure(operation, error);
    }];
}

-(void)cancelGetOfVenueID:(NSString *)venueID
{
    [self cancelAllHTTPOperationsWithMethod:@"GET" path:[NSString stringWithFormat:@"venues/%@", venueID]];
}

#pragma mark - Utilities

-(void)addToFlatCategories:(NSArray *)someCategories accumulator:(NSMutableArray *)flatCategories
{
    for(M5VenueCategory *category in someCategories) {
        [flatCategories addObject:category];
        
        if(category.subcategories)
            [self addToFlatCategories:category.subcategories accumulator:flatCategories];
    }
}

-(NSArray *)flattenCategories:(NSArray *)theCategories
{
    NSMutableArray *flatCategories = [NSMutableArray array];
    [self addToFlatCategories:theCategories accumulator:flatCategories];
    
    [flatCategories sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    
    return flatCategories;
}

-(M5VenueCategory *)venueCategoryForID:(NSString *)venueCategoryID
{
    for(M5VenueCategory *category in self.venueCategories) {
        if([category._id isEqualToString:venueCategoryID])
            return category;
    }
    
    return nil;
}

@end
