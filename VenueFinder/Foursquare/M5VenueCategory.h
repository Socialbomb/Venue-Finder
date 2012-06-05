//
//  M5VenueCategory.h
//  Venue Finder
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface M5VenueCategory : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *pluralName;
@property (nonatomic, strong, readonly) NSString *categoryID;
@property (nonatomic, strong, readonly) NSArray *subcategories;
@property (nonatomic, strong, readonly) NSURL *iconURL;
@property (nonatomic, weak, readonly) M5VenueCategory *parentCategory;  // Weak to avoid retain cycles

// A user-friendly string describing this category's relationships to others
// (e.g. the number of subcategories it has, or if it's a root category).
@property (nonatomic, readonly) NSString *relationshipsDescription;

// The slot this category falls in for alphabetization under its name.
// A number from 0 to 26, for A-Z and then anything else.
@property (nonatomic, assign, readonly) uint alphabetizationRank;

// Uses the name of this venue to compare it to another.
-(NSComparisonResult)compare:(M5VenueCategory *)other;

-(id)initWithDictionary:(NSDictionary *)dictionary;

@end
