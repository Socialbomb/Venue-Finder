//
//  M5FoursquareClient.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import "M5FoursquareClient.h"
#import "AFJSONRequestOperation.h"
#import "CLLocation+M5Utils.h"

static const int M5FoursquareAPITimeout = 15;
static const double M5FoursquareMaxSearchAreaMeters = 10000000000;  // The Foursquare docs say the max searchable region is approximately 10,000 sq km

static NSString * const M5CachedCategoriesDateKey = @"M5CachedCategoriesDate";

@interface M5FoursquareClient ()

@property (nonatomic, strong, readwrite) NSArray *venueCategories;
@property (nonatomic, strong, readwrite) NSDate *cachedCategoriesDate;

@property (nonatomic, readonly) NSString *cachedCategoriesPath;
@property (nonatomic, strong) NSData *cachedCategoriesResponse;

-(void)addToFlatCategories:(NSArray *)someCategories accumulator:(NSMutableArray *)flatCategories;
-(NSArray *)flattenCategories:(NSArray *)theCategories;
-(double)areaCoveredByRegion:(MKCoordinateRegion)mapRegion;
-(NSString *)pathForVenueID:(NSString *)venueID;

@end


@implementation M5FoursquareClient

@synthesize venueCategories;

+(M5FoursquareClient *)sharedClient
{
    static dispatch_once_t onceToken;
    static M5FoursquareClient *staticSharedClient;
    
    dispatch_once(&onceToken, ^{
        staticSharedClient = [[M5FoursquareClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.foursquare.com"]];
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

-(void)handleCategoriesResponse:(NSDictionary *)JSON completion:(void (^)(NSArray *))completion
{
    NSArray *categoryDicts = [[JSON objectForKey:@"response"] objectForKey:@"categories"];
    
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:categoryDicts.count];
    for(NSDictionary *categoryDict in categoryDicts)
        [categories addObject:[[M5VenueCategory alloc] initWithDictionary:categoryDict]];
    
    self.venueCategories = [self flattenCategories:categories];
    
    if(completion)
        completion(self.venueCategories);
}

-(void)getVenueCategoriesIgnoringCache:(BOOL)ignoreCache completion:(void (^)(NSArray *))completion failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    if(ignoreCache || !self.cachedCategoriesDate)
    {
        [self getPath:@"/v2/venues/categories" parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
            self.cachedCategoriesResponse = operation.responseData;
            [self handleCategoriesResponse:JSON completion:completion];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(failure)
                failure(operation, error);
        }];
    }
    else {
        NSError *error;
        NSDictionary *cachedResponse = [NSJSONSerialization JSONObjectWithData:self.cachedCategoriesResponse options:0 error:&error];
        if(!cachedResponse) {
            NSLog(@"Error reading cached venue categories: %@. Reloading from network.", error);
            [self getVenueCategoriesIgnoringCache:YES completion:completion failure:failure];
        }
        else {
            [self handleCategoriesResponse:cachedResponse completion:completion];
        }
    }
}

-(BOOL)mapRegionIsOfSearchableArea:(MKCoordinateRegion)mapRegion
{
    return [self areaCoveredByRegion:mapRegion] <= M5FoursquareMaxSearchAreaMeters;
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
                                   [NSString stringWithFormat:@"%.7f,%.7f", northEastCorner.latitude, northEastCorner.longitude], @"ne",
                                   [NSString stringWithFormat:@"%.7f,%.7f", southWestCorner.latitude, southWestCorner.longitude], @"sw",
                                   nil];
    
    if(categoryID)
        [params setObject:categoryID forKey:@"categoryId"];
    
    [self getPath:@"/v2/venues/search" parameters:params success:^(AFHTTPRequestOperation *operation, id JSON) {
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

-(NSString *)pathForVenueID:(NSString *)venueID
{
    return [@"/v2/venues/" stringByAppendingString:venueID];
}

-(void)getVenueWithID:(NSString *)venueID completion:(void (^)(M5Venue *))completion failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    NSString *path = [self pathForVenueID:venueID];
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
    [self cancelAllHTTPOperationsWithMethod:@"GET" path:[self pathForVenueID:venueID]];
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
    
    [flatCategories sortUsingComparator:^NSComparisonResult(M5VenueCategory *cat1, M5VenueCategory *cat2) {
        if(cat1.alphabetizationRank < cat2.alphabetizationRank)
            return NSOrderedAscending;
        
        if(cat1.alphabetizationRank > cat2.alphabetizationRank)
            return NSOrderedDescending;
        
        return [cat1.name compare:cat2.name options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
    }];
    
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

-(double)areaCoveredByRegion:(MKCoordinateRegion)mapRegion
{
    CLLocationCoordinate2D northEastCorner, southEastCorner, southWestCorner;
    northEastCorner.latitude  = mapRegion.center.latitude  + (mapRegion.span.latitudeDelta  / 2.0);
    northEastCorner.longitude = mapRegion.center.longitude + (mapRegion.span.longitudeDelta / 2.0);
    southWestCorner.latitude  = mapRegion.center.latitude  - (mapRegion.span.latitudeDelta  / 2.0);
    southWestCorner.longitude = mapRegion.center.longitude - (mapRegion.span.longitudeDelta / 2.0);
    
    southEastCorner.latitude = southWestCorner.latitude;
    southEastCorner.longitude = northEastCorner.longitude;
    
    CLLocationDistance height = [CLLocation distanceFromCoordinate:northEastCorner toCoordinate:southEastCorner];
    CLLocationDistance width = [CLLocation distanceFromCoordinate:southWestCorner toCoordinate:southEastCorner];
    
    return width * height;
}

-(void)setCachedCategoriesDate:(NSDate *)cachedCategoriesDate
{
    [[NSUserDefaults standardUserDefaults] setObject:cachedCategoriesDate forKey:M5CachedCategoriesDateKey];
}

-(NSDate *)cachedCategoriesDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:M5CachedCategoriesDateKey];
}

-(NSString *)cachedCategoriesPath
{
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[cachePaths objectAtIndex:0] stringByAppendingPathComponent:@"foursquare-categories.json"];
}

-(void)setCachedCategoriesResponse:(NSData *)cachedCategoriesResponse
{
    if([[NSFileManager defaultManager] createFileAtPath:self.cachedCategoriesPath
                                            contents:cachedCategoriesResponse
                                          attributes:nil])
    {
        self.cachedCategoriesDate = [NSDate date];
    }
}

-(NSData *)cachedCategoriesResponse
{
    NSData *contents = [[NSFileManager defaultManager] contentsAtPath:self.cachedCategoriesPath];
    return contents;
}

@end
