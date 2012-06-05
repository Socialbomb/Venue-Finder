//
//  CLPlacemark+Utils.m
//  Venue Finder
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import "CLPlacemark+M5Utils.h"

NS_INLINE id M5NullIfNil(id obj)
{
    return obj ? obj : [NSNull null];
}

NS_INLINE NSString *M5CommaSeparateNonNullElementsOfArray(NSArray *strings)
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

@implementation CLPlacemark (M5Utils)

-(NSString *)streetAddress
{
    NSString *fromDict = [self.addressDictionary objectForKey:@"Street"];
    if(fromDict)
        return fromDict;
    else if(self.subThoroughfare && self.thoroughfare)
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
    else {
        NSArray *fromDict = [self.addressDictionary objectForKey:@"FormattedAddressLines"];
        if(fromDict.count >= 1)
            return [fromDict objectAtIndex:0];
    }
    
    if(self.streetAddress)
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

-(NSString *)friendlySubtitle
{
    NSArray *fromDict = [self.addressDictionary objectForKey:@"FormattedAddressLines"];
    if(fromDict.count >= 2)
        return [fromDict objectAtIndex:1];

    else if(self.name || self.streetAddress)
    {
        return M5CommaSeparateNonNullElementsOfArray(
                [NSArray arrayWithObjects:
                 M5NullIfNil(self.locality),
                 M5NullIfNil(self.administrativeArea),
                 M5NullIfNil(self.ISOcountryCode),
                 nil]);
    }
    else if(self.locality)
    {
        return M5CommaSeparateNonNullElementsOfArray(
                [NSArray arrayWithObjects:
                 M5NullIfNil(self.administrativeArea),
                 M5NullIfNil(self.ISOcountryCode),
                 nil]);
    }
    else if(self.administrativeArea)
        return self.ISOcountryCode;
    
    return nil;
}

@end
