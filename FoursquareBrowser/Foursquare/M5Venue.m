//
//  M5Venue.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "M5Venue.h"
#import "M5FoursquareClient.h"

#pragma mark - M5VenueLocation

@interface M5VenueLocation ()

@property (nonatomic, strong, readwrite) NSString *streetAddress;
@property (nonatomic, strong, readwrite) NSString *crossStreet;
@property (nonatomic, strong, readwrite) NSString *city;
@property (nonatomic, strong, readwrite) NSString *state;
@property (nonatomic, strong, readwrite) NSString *postalCode;
@property (nonatomic, strong, readwrite) NSString *country;

@property (nonatomic, assign, readwrite) CLLocationCoordinate2D coordinate;

@end


@implementation M5VenueLocation

@synthesize coordinate, city, state, country, postalCode, crossStreet, streetAddress;

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    if(self) {
        NSDictionary *locationInfo = [dictionary objectForKey:@"location"];
        
        self.coordinate = CLLocationCoordinate2DMake([[locationInfo objectForKey:@"lat"] doubleValue],
                                                     [[locationInfo objectForKey:@"lng"] doubleValue]);
        
        self.city = [locationInfo objectForKey:@"city"];
        self.state = [locationInfo objectForKey:@"state"];
        self.country = [locationInfo objectForKey:@"country"];
        self.postalCode = [locationInfo objectForKey:@"postalCode"];
        self.crossStreet = [locationInfo objectForKey:@"crossStreet"];
        self.streetAddress = [locationInfo objectForKey:@"address"];
    }
    
    return self;
}

@end


#pragma mark - M5VenueStats

@interface M5VenueStats ()

@property (nonatomic, assign, readwrite) uint totalCheckins;
@property (nonatomic, assign, readwrite) uint totalUsers;
@property (nonatomic, assign, readwrite) uint totalTips;
@property (nonatomic, assign, readwrite) uint currentCheckinCount;

@end


@implementation M5VenueStats

@synthesize totalTips, totalUsers, totalCheckins, currentCheckinCount;

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    if(self) {
        self.currentCheckinCount = [[[dictionary objectForKey:@"hereNow"] objectForKey:@"count"] unsignedIntValue];
        
        NSDictionary *stats = [dictionary objectForKey:@"stats"];
        self.totalCheckins = [[stats objectForKey:@"checkinsCount"] unsignedIntValue];
        self.totalUsers = [[stats objectForKey:@"usersCount"] unsignedIntValue];
        self.totalTips = [[stats objectForKey:@"tipCount"] unsignedIntValue];
    }
    
    return self;
}

@end



#pragma mark - M5Venue

@interface M5Venue ()

@property (nonatomic, strong, readwrite) NSString *_id;
@property (nonatomic, strong, readwrite) NSURL *venueURL;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *venueDescription;
@property (nonatomic, strong, readwrite) NSDate *createdAt;
@property (nonatomic, strong, readwrite) M5VenueLocation *location;

@property (nonatomic, strong, readwrite) NSString *twitterHandle;
@property (nonatomic, strong, readwrite) NSString *formattedPhoneNumber;
@property (nonatomic, strong, readwrite) NSString *phoneNumber;
@property (nonatomic, strong, readwrite) NSURL *websiteURL;
@property (nonatomic, assign, readwrite) BOOL verified;

@property (nonatomic, strong, readwrite) M5VenueStats *stats;

@property (nonatomic, strong, readwrite) NSArray *tags;
@property (nonatomic, strong, readwrite) NSArray *categories;  // The primary category is always first

@end


@implementation M5Venue

@synthesize _id, name, location, stats, venueURL, tags, title, subtitle, verified, createdAt, categories, coordinate, websiteURL, venueDescription, formattedPhoneNumber, phoneNumber, twitterHandle;

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        self._id = [dictionary objectForKey:@"id"];
        self.name = [dictionary objectForKey:@"name"];
        self.venueURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://foursquare.com/v/%@", self._id]];
        self.venueDescription = [dictionary objectForKey:@"description"];
        
        if([dictionary objectForKey:@"createdAt"])
            self.createdAt = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:@"createdAt"] doubleValue]];
        
        self.location = [[M5VenueLocation alloc] initWithDictionary:dictionary];
        
        self.stats = [[M5VenueStats alloc] initWithDictionary:dictionary];
        
        NSDictionary *contactDict = [dictionary objectForKey:@"contact"];
        self.twitterHandle = [contactDict objectForKey:@"twitter"];
        self.formattedPhoneNumber = [contactDict objectForKey:@"formattedPhone"];
        self.phoneNumber = [contactDict objectForKey:@"phone"];
        self.websiteURL = [NSURL URLWithString:[dictionary objectForKey:@"url"]];
        
        self.tags = [dictionary objectForKey:@"tags"];
        self.verified = [[dictionary objectForKey:@"verified"] intValue] == 1;
        
        NSArray *categoryDicts = [dictionary objectForKey:@"categories"];
        if(categoryDicts.count > 0) {
            M5VenueCategory *primaryCategory;
            
            NSMutableArray *mutableCategories = [NSMutableArray arrayWithCapacity:categoryDicts.count];
            for(NSDictionary *dict in categoryDicts) {
                NSString *categoryID = [dict objectForKey:@"id"];
                M5VenueCategory *category = [[M5FoursquareClient sharedClient] venueCategoryForID:categoryID];
                
                if([[dict objectForKey:@"primary"] intValue] == 1)
                    primaryCategory = category;
                else
                    [mutableCategories addObject:category];
            }
            
            [mutableCategories sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
            
            if(primaryCategory)
                [mutableCategories insertObject:primaryCategory atIndex:0];
            
            self.categories = mutableCategories;
        }
    }
    
    return self;
}

-(NSString *) description {
	return [NSString stringWithFormat:@"%@ (%@)", self.name, self._id];
}

#pragma mark MKAnnotation implementation

-(NSString *)title
{
    return self.name;
}

-(CLLocationCoordinate2D)coordinate
{
    return self.location.coordinate;
}

@end
