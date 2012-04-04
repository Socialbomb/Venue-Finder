//
//  CLPlacemark+Utils.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CLPlacemark+Utils.h"

#define M5NullIfNil(obj) (obj ? obj : [NSNull null])

@implementation CLPlacemark (Utils)

-(NSString *)streetAddress
{
    if(self.subThoroughfare && self.thoroughfare)
        return [NSString stringWithFormat:@"%@ %@", self.subThoroughfare, self.thoroughfare];
    else if(self.thoroughfare)
        return self.thoroughfare;
    else if(self.subThoroughfare)
        return self.subThoroughfare;
    
    return nil;
}

-(NSString *)friendlyTitle
{
    if(self.name)
        return self.name;
    else if(self.streetAddress)
        return self.streetAddress;
    else if(self.locality)
        return self.locality;
    else if(self.administrativeArea)
        return self.administrativeArea;
    else if(self.country)
        return self.country;
    else if(self.inlandWater)
        return self.inlandWater;
    else if(self.ocean)
        return self.ocean;
    else if(self.areasOfInterest.count > 0)
        return [self.areasOfInterest objectAtIndex:0];
    
    return nil;
}

+(NSString *)commaSeparateNonNullElementsOfArray:(NSArray *)strings
{
    NSMutableString *s;
    
    for(NSString *string in strings) {
        if((id)string != [NSNull null]) {
            if(s)
                [s appendFormat:@", %@", string];
            else
                s = [string mutableCopy];
        }
    }
    
    return s;
}

-(NSString *)friendlySubtitle
{
    if(self.name || self.streetAddress)
    {
        return [CLPlacemark commaSeparateNonNullElementsOfArray:
                [NSArray arrayWithObjects:
                 M5NullIfNil(self.locality),
                 M5NullIfNil(self.administrativeArea),
                 M5NullIfNil(self.ISOcountryCode),
                 nil]];
    }
    else if(self.locality)
    {
        return [CLPlacemark commaSeparateNonNullElementsOfArray:
                [NSArray arrayWithObjects:
                 M5NullIfNil(self.administrativeArea),
                 M5NullIfNil(self.ISOcountryCode),
                 nil]];
    }
    else if(self.administrativeArea)
        return self.ISOcountryCode;
    
    return nil;
}

@end
