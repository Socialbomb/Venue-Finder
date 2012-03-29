//
//  CLPlacemark+Utils.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CLPlacemark+Utils.h"

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

@end
