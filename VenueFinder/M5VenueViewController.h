//  M5VenueViewController.h
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import <UIKit/UIKit.h>
#import "M5Venue.h"

// The view controller that presents the details of a specific venue.
// Triggered by tapping the blue arrow on map pin callouts.

@interface M5VenueViewController : UIViewController

// Create a new instance with the given abbreviated venue (i.e., a venue object
// that resulted from a search and is thus missing fields).
-(id)initWithAbbreviatedVenue:(M5Venue *)theAbbreviatedVenue;

@end
