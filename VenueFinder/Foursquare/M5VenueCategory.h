//
//  M5VenueCategory.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface M5VenueCategory : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *pluralName;
@property (nonatomic, assign, readonly) uint alphabetizationRank; // 0 - 26 (A - Z, then anything else)
@property (nonatomic, strong, readonly) NSString *_id;
@property (nonatomic, strong, readonly) NSArray *subcategories;
@property (nonatomic, strong, readonly) NSURL *iconURL;
@property (nonatomic, weak, readonly) M5VenueCategory *parentCategory;

@property (nonatomic, readonly) NSString *relationshipsDescription;

-(id)initWithDictionary:(NSDictionary *)dictionary;

@end
