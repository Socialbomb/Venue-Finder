//
//  M5Venue.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "M5Venue.h"

@interface M5Venue ()

@property (nonatomic, strong, readwrite) NSString *_id;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) CLLocationCoordinate2D coordinate;

@end


@implementation M5Venue

@synthesize _id, name, coordinate;

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        self._id = [dictionary objectForKey:@"id"];
        self.name = [dictionary objectForKey:@"name"];
        
        NSDictionary *locationInfo = [dictionary objectForKey:@"location"];
        
        self.coordinate = CLLocationCoordinate2DMake([[locationInfo objectForKey:@"lat"] doubleValue],
                                                     [[locationInfo objectForKey:@"lng"] doubleValue]);
    }
    
    return self;
}

-(NSString *) description {
	return [NSString stringWithFormat:@"%@ (%@)", self.name, self._id];
}

-(NSString *)title
{
    return self.name;
}

@end
