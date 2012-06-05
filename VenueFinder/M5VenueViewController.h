//
//  M5VenueViewController.h
//  Venue Finder
//
//  Created by Tim Clem on 3/27/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "M5Venue.h"

// The view controller that presents the details of a specific venue.
// Triggered by tapping the blue arrow on map pin callouts.

@interface M5VenueViewController : UIViewController

// Create a new instance with the given abbreviated venue (i.e., a venue object
// that resulted from a search and is thus missing fields).
-(id)initWithAbbreviatedVenue:(M5Venue *)theAbbreviatedVenue;

@end
