//  M5VenueCategory.m
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import "M5VenueCategory.h"

static const int M5PreferredCategoryIconSize = 64;  // The API gives us a bunch of icon sizes. This is the one we prefer to pull out for iconURL.

@interface M5VenueCategory ()

@property (nonatomic, weak, readwrite) M5VenueCategory *parentCategory;
@property (nonatomic, strong, readwrite) NSString *categoryID;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *pluralName;
@property (nonatomic, assign, readwrite) uint alphabetizationRank;
@property (nonatomic, strong, readwrite) NSArray *subcategories;
@property (nonatomic, strong, readwrite) NSURL *iconURL;

@end


@implementation M5VenueCategory

@synthesize name = _name;
@synthesize pluralName = _pluralName;
@synthesize categoryID = _categoryID;
@synthesize subcategories = _subcategories;
@synthesize iconURL = _iconURL;
@synthesize parentCategory = _parentCategory;
@synthesize alphabetizationRank = _alphabetizationRank;

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        self.categoryID = [dictionary objectForKey:@"id"];
        self.name = [dictionary objectForKey:@"name"];
        self.pluralName = [dictionary objectForKey:@"pluralName"];
        
        // Convert name to ASCII to figure out how we should alphabetize it
        NSData *asciiNameData = [[self.name lowercaseString] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *asciifiedName = [[NSString alloc] initWithData:asciiNameData encoding:NSASCIIStringEncoding];
        NSCharacterSet *letterCharSet = [NSCharacterSet letterCharacterSet];
        NSCharacterSet *whitespaceCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        char firstLetter = 0;
        
        // Find the first non-whitespace character. If it's a letter, we'll use that as the rank.
        // Otherwise it goes last.
        for(NSUInteger i = 0; i < asciifiedName.length; i++) {
            unichar c = [asciifiedName characterAtIndex:i];
            
            if(![whitespaceCharSet characterIsMember:c]) {
                if([letterCharSet characterIsMember:c])
                    firstLetter = (char)c; // This conversion is safe; we've already converted to ASCII

                break;
            }
        }
        
        if(firstLetter != 0)
            self.alphabetizationRank = firstLetter - 'a';
        else
            self.alphabetizationRank = 26;
        
        
        int actualIconSize = 0;
        
        NSDictionary *iconInfo = [dictionary objectForKey:@"icon"];
        NSArray *iconSizes = [iconInfo objectForKey:@"sizes"];
        
        // Use preferred icon size if this category has an image at that size...
        for(NSNumber *iconSize in iconSizes) {
            if(iconSize.intValue == M5PreferredCategoryIconSize) {
                actualIconSize = iconSize.intValue;
                break;
            }
        }
        
        // ... otherwise, just use the first size
        if(actualIconSize == 0)
            actualIconSize = [[iconSizes objectAtIndex:0] intValue];
        
        NSString *iconURLString = [NSString stringWithFormat:@"%@%d%@", [iconInfo objectForKey:@"prefix"], actualIconSize, [iconInfo objectForKey:@"name"]];
        self.iconURL = [NSURL URLWithString:iconURLString];
        
        NSArray *subcategoriesArray = [dictionary objectForKey:@"categories"];
        if(subcategoriesArray && subcategoriesArray.count > 0) {
            NSMutableArray *mutableSubcategories = [NSMutableArray arrayWithCapacity:subcategoriesArray.count];
            
            for(NSDictionary *dict in subcategoriesArray) {
                M5VenueCategory *cat = [[M5VenueCategory alloc] initWithDictionary:dict];
                cat.parentCategory = self;
                
                [mutableSubcategories addObject:cat];
            }
            
            self.subcategories = mutableSubcategories;
        }
    }
    
    return self;
}

-(NSString *)relationshipsDescription
{
    if(self.parentCategory) {
        if(self.subcategories)
            return [NSString stringWithFormat:@"Parent category: %@; %u subcategories", self.parentCategory.name, self.subcategories.count];
        else
            return [NSString stringWithFormat:@"Parent category: %@", self.parentCategory.name];
    }
    else
        return [NSString stringWithFormat:@"Root category; %u subcategories", self.subcategories.count];
}

-(NSComparisonResult)compare:(M5VenueCategory *)other
{
    if(self.alphabetizationRank < other.alphabetizationRank)
        return NSOrderedAscending;
    
    if(self.alphabetizationRank > other.alphabetizationRank)
        return NSOrderedDescending;
    
    return [self.name compare:other.name options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
}

@end
