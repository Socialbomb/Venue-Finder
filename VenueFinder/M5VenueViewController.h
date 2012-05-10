//
//  M5VenueViewController.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "M5Venue.h"

@interface M5VenueViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

-(id)initWithAbbreviatedVenue:(M5Venue *)theAbbreviatedVenue;

@end
