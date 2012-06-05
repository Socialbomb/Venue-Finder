//
//  M5ViewController.m
//  Venue Finder
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CLLocation+M5Utils.h"
#import "CLPlacemark+M5Utils.h"
#import "SBTableAlert.h"
#import "M5ViewController.h"
#import "M5FoursquareClient.h"
#import "M5CategoriesController.h"
#import "M5VenueViewController.h"
#import "M5PlacemarkAnnotation.h"

typedef enum {
    M5NoAlert,
    M5AlertCategoryError,
    M5AlertGoToLocation,
    M5VenueSearchError,
} M5AlertType;

// Min time between allowing the user to refresh the categories list (seconds).
// The docs here https://developer.foursquare.com/docs/venues/categories say not to do this more than once a session.
static const CFTimeInterval M5MinCategoryRefreshInterval = 60.0 * 60.0;

@interface M5ViewController () <MKMapViewDelegate, UIAlertViewDelegate, M5CategoriesControllerDelegate, SBTableAlertDataSource, SBTableAlertDelegate, UITextFieldDelegate, CLLocationManagerDelegate> {
    M5AlertType currentAlert;
    NSArray *flattenedCategories;
    M5VenueCategory *currentCategory;
    BOOL didAppear;
    
    BOOL viewAlreadyLoaded;
    MKCoordinateRegion lastMapRegion;
    NSArray *lastMapVenues;
    
    UIAlertView *goAlert;
    NSArray *placemarks;
    
    BOOL mapIsCurled;
    BOOL redoSearchIsVisible;
    
    BOOL locationAuthPending;  // Yes until we know our location auth status
    BOOL handledInitialUserLocation;  // NO until we've gotten some notice about the status of locating the user
    BOOL doVenueSearchAfterCategoriesLoad;  // YES if we locate the user before we finish loading categories
    BOOL showRedoSearchAfterCategoriesLoad;  // YES if there was an error locating the user before categories finished loading
    
    AFImageRequestOperation *categoryIconRequest;
    
    CLLocationManager *locationManager;
}

@property (weak, nonatomic) IBOutlet UIView *curlContainer;
@property (weak, nonatomic) IBOutlet UIView *mapContainer;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIView *pageCurlView;
@property (weak, nonatomic) IBOutlet UILabel *categoriesDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoriesWaitLabel;
@property (weak, nonatomic) IBOutlet UIButton *curlDismissalButton;
@property (weak, nonatomic) IBOutlet UIButton *categoryButton;
@property (weak, nonatomic) IBOutlet UILabel *searchAreaTooBigLabel;
@property (weak, nonatomic) IBOutlet UIView *redoSearchContainer;
@property (weak, nonatomic) IBOutlet UIButton *redoSearchButton;

-(IBAction)categoryButtonTapped:(id)sender;
-(IBAction)refreshButtonTapped:(UIButton *)sender;
-(IBAction)goButtonTapped:(id)sender;
-(IBAction)mapTypeTapped:(UISegmentedControl *)sender;
-(IBAction)reloadCategoriesTapped:(id)sender;
-(IBAction)pageCurlButtonTapped:(UIBarButtonItem *)sender;
-(IBAction)curlDismissalButtonTapped:(id)sender;

-(void)loadCategoriesIgnoringCache:(BOOL)ignoreCache;
-(void)refreshVenues;
-(void)setCategoryLabelFromCategory:(M5VenueCategory *)category;

-(void)setMapVenues:(NSArray *)venues;

-(CLRegion *)CLRegionWithMapRegion:(MKCoordinateRegion)region;
-(void)goToPlacemark:(CLPlacemark *)placemark;

-(void)curlMap;
-(void)uncurlMap;

-(void)showRedoSearch;
-(void)hideRedoSearch;

-(void)showAreaTooLargeWarning;  // Will show the "Redo Search" area if it's not already visible

-(NSString *)stringWithShortTimeSince:(NSDate *)date;

@end


@implementation M5ViewController

@synthesize curlContainer;
@synthesize mapContainer;
@synthesize mapView;
@synthesize toolbar;
@synthesize pageCurlView;
@synthesize categoriesDateLabel;
@synthesize categoriesWaitLabel;
@synthesize curlDismissalButton;
@synthesize categoryButton;
@synthesize searchAreaTooBigLabel;
@synthesize redoSearchContainer;
@synthesize redoSearchButton;

#pragma mark - View Lifecycle

-(id)init
{
    self = [super initWithNibName:@"M5ViewController" bundle:nil];
    if(self) {
        self.title = @"Map";
        
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            locationAuthPending = YES;
            
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
        }
    }
    
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    if(viewAlreadyLoaded) {
        // Our view got destroyed; restore the map region and category
        [self setCategoryLabelFromCategory:currentCategory];
        [self setMapVenues:lastMapVenues];
        [mapView setRegion:lastMapRegion animated:NO];
    }
    
    viewAlreadyLoaded = YES;
    
    MKUserTrackingBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:mapView];
    
    NSMutableArray *toolbarItems = [toolbar.items mutableCopy];
    [toolbarItems insertObject:userTrackingButton atIndex:0];
    toolbar.items = toolbarItems;
    
    curlContainer.backgroundColor = [UIColor underPageBackgroundColor];  // This one's not available in IB for some reason
    
    categoryButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);  // Add some padding between the category icon and the text
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!didAppear) {
        // First appearance. Find the user (if we can) and load categories
        if(!locationAuthPending)
            mapView.userTrackingMode = MKUserTrackingModeFollow;
        
        [self loadCategoriesIgnoringCache:NO];
    }
    
    didAppear = YES;
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // If a new controller is getting pushed on the stack, show the nav bar for it.
    // If it's just a modal (e.g. the category selector), do nothing.
    if(self.navigationController.topViewController != self)
        [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(void)viewDidUnload
{
    [self setMapView:nil];
    [self setToolbar:nil];
    [self setPageCurlView:nil];
    [self setCategoriesDateLabel:nil];
    [self setCurlContainer:nil];
    [self setMapContainer:nil];
    [self setCurlDismissalButton:nil];
    [self setCategoryButton:nil];
    [self setCategoriesWaitLabel:nil];
    [self setSearchAreaTooBigLabel:nil];
    [self setRedoSearchContainer:nil];
    [self setRedoSearchButton:nil];
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Interaction

-(IBAction)categoryButtonTapped:(id)sender
{
    [self uncurlMap];
    
    // We present the CategoriesController inside a UINavigationController so that its search bar will handle
    // the automatic hiding of the navigation bar.
    
    M5CategoriesController *categoriesController = [[M5CategoriesController alloc] initWithCategories:flattenedCategories];
    categoriesController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:categoriesController];
    navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    [self presentModalViewController:navController animated:YES];
}

-(IBAction)refreshButtonTapped:(UIButton *)sender
{
    if([[M5FoursquareClient sharedClient] mapRegionIsOfSearchableArea:mapView.region])    
        [self refreshVenues];
    else
        [self showAreaTooLargeWarning];
}

-(void)showAreaTooLargeWarning
{
    [self showRedoSearch];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        redoSearchButton.alpha = 0;
        searchAreaTooBigLabel.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:2.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            redoSearchButton.alpha = 1;
            searchAreaTooBigLabel.alpha = 0;
        } completion:nil];
    }];
}

-(IBAction)goButtonTapped:(id)sender
{
    [self uncurlMap];
    
    currentAlert = M5AlertGoToLocation;
    
    goAlert = [[UIAlertView alloc] initWithTitle:@"Where to, mister?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Allons-y!", nil];
    goAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [goAlert textFieldAtIndex:0];
    textField.placeholder = @"Address or placename";
    textField.enablesReturnKeyAutomatically = YES;
    textField.returnKeyType = UIReturnKeyGo;
    textField.delegate = self;
    [goAlert show];
}

-(IBAction)mapTypeTapped:(UISegmentedControl *)sender
{
    MKMapType newType;
    if(sender.selectedSegmentIndex == 0) newType = MKMapTypeStandard;
    else if(sender.selectedSegmentIndex == 1) newType = MKMapTypeSatellite;
    else newType = MKMapTypeHybrid;
    
    if(mapView.mapType != newType) {
        [self uncurlMap];
        mapView.mapType = newType;
    }
}

-(IBAction)reloadCategoriesTapped:(id)sender
{
    CFTimeInterval now = [[NSDate date] timeIntervalSince1970];
    CFTimeInterval then = [[M5FoursquareClient sharedClient].cachedCategoriesDate timeIntervalSince1970];
    CFTimeInterval diff = MAX(1, now - then);
    
    if(diff < M5MinCategoryRefreshInterval) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            categoriesWaitLabel.alpha = 1;
            categoriesDateLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:2.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                categoriesWaitLabel.alpha = 0;
                categoriesDateLabel.alpha = 1;
            } completion:nil];
        }];
    }
    else {
        [self uncurlMap];
        [self loadCategoriesIgnoringCache:YES];
    }
}

-(IBAction)pageCurlButtonTapped:(UIBarButtonItem *)sender
{
    if(mapIsCurled)
        [self uncurlMap];
    else
        [self curlMap];
}

-(IBAction)curlDismissalButtonTapped:(id)sender
{
    [self uncurlMap];
}

-(void)curlMap
{
    if(mapIsCurled)
        return;
    
    NSString *timeAgo = [self stringWithShortTimeSince:[M5FoursquareClient sharedClient].cachedCategoriesDate];
    categoriesDateLabel.text = [NSString stringWithFormat:@"Categories last updated %@", timeAgo];
    
    [curlContainer insertSubview:pageCurlView belowSubview:mapContainer];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect mapContainerFrame = mapContainer.frame;
        mapContainerFrame.origin.y = -125;
        mapContainer.frame = mapContainerFrame;
    } completion:nil];
    
    curlDismissalButton.userInteractionEnabled = YES;
    mapIsCurled = YES;
}

-(void)uncurlMap
{
    if(!mapIsCurled)
        return;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect mapContainerFrame = mapContainer.frame;
        mapContainerFrame.origin.y = 0;
        mapContainer.frame = mapContainerFrame;
    } completion:^(BOOL finished) {
        [pageCurlView removeFromSuperview];
    }];
    
    curlDismissalButton.userInteractionEnabled = NO;
    mapIsCurled = NO;
}

-(void)showRedoSearch
{
    if(redoSearchIsVisible)
        return;
    
    redoSearchContainer.hidden = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect redoSearchFrame = redoSearchContainer.frame;
        redoSearchFrame.origin.y -= redoSearchFrame.size.height;
        redoSearchContainer.frame = redoSearchFrame;
    } completion:nil];
    
    redoSearchIsVisible = YES;
}

-(void)hideRedoSearch
{
    if(!redoSearchIsVisible)
        return;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect redoSearchFrame = redoSearchContainer.frame;
        redoSearchFrame.origin.y += redoSearchFrame.size.height;
        redoSearchContainer.frame = redoSearchFrame;
    } completion:^(BOOL finished) {
        redoSearchContainer.hidden = YES;
    }];
    
    redoSearchIsVisible = NO;
}

#pragma mark - MKMapViewDelegate

-(void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    // This may have been a tap on the user tracking button in the toolbar; unfurl the map just in case
    [self uncurlMap];
}

-(void)mapView:(MKMapView *)theMapView regionDidChangeAnimated:(BOOL)animated
{    
    CLLocationCoordinate2D oldCenter = lastMapRegion.center;
    lastMapRegion = mapView.region;
    
    // Show the redo search thing if this isn't one of our initial locations, and if we've moved more than
    // a tiny amount (as happens when the GPS signal isn't so hot)
    if(handledInitialUserLocation) {
        CLLocationDistance dist = [CLLocation distanceFromCoordinate:oldCenter toCoordinate:mapView.region.center];
        if(dist > 10)        
            [self showRedoSearch];
    }
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{   
    // Ignore this (even though it fires?) if we aren't authed for CoreLocation stuff
    if(locationAuthPending)
        return;
    
    if(!handledInitialUserLocation) {
        // This is our first true fix on the user; do a search if we have the categories.
        // Otherwise set a flag that the category load thign will read.
        
        handledInitialUserLocation = YES;
        
        if(flattenedCategories)
            [self refreshVenues];
        else
            doVenueSearchAfterCategoriesLoad = YES;
    }
}

-(void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{   
    // Ignore this if we're still waiting for approval
    if(locationAuthPending)
        return;
    
    if(!handledInitialUserLocation) {
        // We're not going to be able to find the user, apparently.
        // Just show the refresh button (or mark it to be shown after categories load, if necessary)
        
        handledInitialUserLocation = YES;
        
        if(flattenedCategories)
            [self showRedoSearch];
        else
            showRedoSearchAfterCategoriesLoad = YES;
    }
}

-(MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if([annotation isKindOfClass:[M5Venue class]]) {
        MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"VenuePin"];
        if(!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"VenuePin"];
            pin.canShowCallout = YES;
            
            UIButton *accessory = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pin.rightCalloutAccessoryView = accessory;
        }
        
        return pin;
    }
    else if([annotation isKindOfClass:[M5PlacemarkAnnotation class]]) {
        MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"PlacePin"];
        if(!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PlacePin"];
            pin.pinColor = MKPinAnnotationColorPurple;
            pin.animatesDrop = YES;
            pin.canShowCallout = YES;
        }
        
        return pin;
    }
    
    return nil;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    M5Venue *venue = (M5Venue *)view.annotation;

    M5VenueViewController *venueVC = [[M5VenueViewController alloc] initWithAbbreviatedVenue:venue];
    [self.navigationController pushViewController:venueVC animated:YES];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(currentAlert == M5AlertCategoryError) {
        [self loadCategoriesIgnoringCache:NO];
    }
    else if(currentAlert == M5VenueSearchError) {
        // Forcibly allow the user to retry the search (the redo search thing may not have been visible
        // if this was the search we do on app launch)
        [self showRedoSearch];
    }
    else if(currentAlert == M5AlertGoToLocation) {
        if(buttonIndex != alertView.cancelButtonIndex) {
            NSString *text = [alertView textFieldAtIndex:0].text;
            
            [self showHUDFromViewWithText:@"Searching" details:@"finding location" dimScreen:YES];
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            [geocoder geocodeAddressString:text inRegion:[self CLRegionWithMapRegion:mapView.region] completionHandler:^(NSArray *thePlacemarks, NSError *error) {
                [self hideAllHUDsFromView];
                
                if(error || thePlacemarks.count == 0) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alas!" message:@"There was an error looking up the address you typed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                else {
                    if(thePlacemarks.count == 1) {
                        CLPlacemark *placemark = [thePlacemarks objectAtIndex:0];
                        [self goToPlacemark:placemark];
                    }
                    else {
                        placemarks = thePlacemarks;
                        SBTableAlert *tableAlert = [[SBTableAlert alloc] initWithTitle:@"Which location?" cancelButtonTitle:@"Cancel" messageFormat:nil];
                        tableAlert.delegate = self;
                        tableAlert.dataSource = self;
                        [tableAlert show];
                    }
                }
            }];
        }
    }
    
    goAlert = nil;
    currentAlert = M5NoAlert;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if(currentAlert == M5AlertGoToLocation)
        return [alertView textFieldAtIndex:0].text.length > 0;
    
    return YES;
}

#pragma mark - UITextFieldDelegate

// We are the delegate of the text field in the dialog box that comes up when you hit the location search button
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [goAlert dismissWithClickedButtonIndex:goAlert.firstOtherButtonIndex animated:YES];
    return YES;
}

#pragma mark - Guts

-(void)setCategoryLabelFromCategory:(M5VenueCategory *)category
{
    [categoryIconRequest cancel];
    categoryIconRequest = nil;
    
    if(!category) {
        [categoryButton setTitle:@"All categories" forState:UIControlStateNormal];
        [categoryButton setImage:[UIImage imageNamed:@"44-shoebox.png"] forState:UIControlStateNormal];
    }
    else {
        [categoryButton setTitle:category.pluralName forState:UIControlStateNormal];
        [categoryButton setImage:[UIImage imageNamed:@"44-shoebox.png"] forState:UIControlStateNormal];
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:category.iconURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
        req.HTTPShouldHandleCookies = NO;
        req.HTTPShouldUsePipelining = YES;
        
        const float desiredIconHeight = 25;
        
        categoryIconRequest = [AFImageRequestOperation imageRequestOperationWithRequest:req imageProcessingBlock:^UIImage *(UIImage *img) {
            // Scale the image down. Setting content mode on a UIButton's imageView doesn't work when it's highlighted, so we just make the image manually.
            UIImage *scaledImg = [UIImage imageWithCGImage:[img CGImage]
                                                     scale:img.size.height / desiredIconHeight * [UIScreen mainScreen].scale
                                               orientation:UIImageOrientationUp];
            
            return scaledImg;
        } success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            [categoryButton setImage:image forState:UIControlStateNormal];
        } failure:nil];
        
        [categoryIconRequest start];
    }
}

-(void)loadCategoriesIgnoringCache:(BOOL)ignoreCache
{
    [self showHUDFromViewWithText:@"Loading" details:@"fetching categories" dimScreen:YES];
    [[M5FoursquareClient sharedClient] getVenueCategoriesIgnoringCache:ignoreCache completion:^(NSArray *theCategories) {
        currentCategory = nil;
        [self setCategoryLabelFromCategory:nil];
        [self setMapVenues:nil];
        
        flattenedCategories = theCategories;
        
        [self hideAllHUDsFromView];
        
        // Check our flags for initial search/redo search stuff:
        if(doVenueSearchAfterCategoriesLoad)
            [self refreshVenues];
        else if(showRedoSearchAfterCategoriesLoad)
            [self showRedoSearch];
        
        doVenueSearchAfterCategoriesLoad = showRedoSearchAfterCategoriesLoad = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self hideAllHUDsFromView];
        
        currentAlert = M5AlertCategoryError;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ruh Roh!"
                                                        message:@"Couldn't load venue categories!"
                                                       delegate:self
                                              cancelButtonTitle:@"Retry"
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

-(void)refreshVenues
{
    if(![[M5FoursquareClient sharedClient] mapRegionIsOfSearchableArea:mapView.region]) {
        [self showAreaTooLargeWarning];
        
        return;
    }
    
    [self showHUDFromViewWithText:@"Searching" details:@"finding venues" dimScreen:YES];
    [[M5FoursquareClient sharedClient] getVenuesOfCategory:currentCategory.categoryID
                                               inMapRegion:mapView.region
                                                completion:^(NSArray *venues) {
                                                    [self hideRedoSearch];
                                                    [self hideAllHUDsFromView];
                                                    
                                                    [self setMapVenues:venues];
                                                    lastMapVenues = venues;
                                                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                    [self hideAllHUDsFromView];
                                                    
                                                    currentAlert = M5VenueSearchError;
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ruh Roh!"
                                                                                                    message:@"Couldn't load venues! Try again later."
                                                                                                   delegate:self
                                                                                          cancelButtonTitle:@"OK"
                                                                                          otherButtonTitles:nil];
                                                    [alert show];
                                                }];
}

-(void)setMapVenues:(NSArray *)venues
{
    for(id<MKAnnotation> annotation in mapView.annotations) {
        if([annotation isKindOfClass:[M5Venue class]])
            [mapView removeAnnotation:annotation];
    }
    
    for(M5Venue *venue in venues)
        [mapView addAnnotation:venue];
}

#pragma mark - M5CategoriesControllerDelegate

-(void)categoriesController:(M5CategoriesController *)categoriesController didSelectCategory:(M5VenueCategory *)category
{
    [self setCategoryLabelFromCategory:category];

    [categoriesController dismissViewControllerAnimated:YES completion:^{
        if(currentCategory == category)
            return;
        
        currentCategory = category;
        
        if([[M5FoursquareClient sharedClient] mapRegionIsOfSearchableArea:mapView.region])
            [self refreshVenues];
        else {
            [self setMapVenues:nil];
            [self showAreaTooLargeWarning];
        }
    }];
}

-(void)categoriesControllerDidCancel:(M5CategoriesController *)categoriesController
{
    [categoriesController dismissModalViewControllerAnimated:YES];
}

#pragma mark - SBTableAlertDataSource & SBTableAlertDelegate

-(NSInteger)numberOfSectionsInTableAlert:(SBTableAlert *)tableAlert
{
    return 1;
}

-(NSInteger)tableAlert:(SBTableAlert *)tableAlert numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)placemarks.count;
}

-(UITableViewCell *)tableAlert:(SBTableAlert *)tableAlert cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableAlert.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    CLPlacemark *placemark = [placemarks objectAtIndex:(NSUInteger)indexPath.row];
    cell.textLabel.text = placemark.friendlyTitle;
    cell.detailTextLabel.text = placemark.friendlySubtitle;
    
    return cell;
}

-(void)tableAlert:(SBTableAlert *)tableAlert didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLPlacemark *placemark = [placemarks objectAtIndex:(NSUInteger)indexPath.row];
    [self goToPlacemark:placemark];
}

#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // We get told this initially for some reason...
    if(status == kCLAuthorizationStatusNotDetermined)
        return;
    
    locationAuthPending = NO;
    
    if(status == kCLAuthorizationStatusAuthorized)
        mapView.userTrackingMode = MKUserTrackingModeFollow;
    
    locationManager.delegate = nil;
    locationManager = nil;
}

#pragma mark - Utilities

-(CLRegion *)CLRegionWithMapRegion:(MKCoordinateRegion)region
{
    CLLocationCoordinate2D northEastCorner, southEastCorner;
    northEastCorner.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0);
    northEastCorner.longitude = region.center.longitude + (region.span.longitudeDelta / 2.0);
    southEastCorner.latitude = region.center.latitude  - (region.span.latitudeDelta  / 2.0);
    southEastCorner.longitude = northEastCorner.longitude;
    
    CLLocationDistance height = [CLLocation distanceFromCoordinate:northEastCorner toCoordinate:southEastCorner];
    
    return [[CLRegion alloc] initCircularRegionWithCenter:region.center radius:height / 2.0 identifier:@"GeocodingRegion"];
}

-(void)goToPlacemark:(CLPlacemark *)placemark
{
    if(placemark.region)
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(placemark.region.center, placemark.region.radius, placemark.region.radius) animated:YES];
    else
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(placemark.location.coordinate, 1000, 1000) animated:YES];
    
    for(id<MKAnnotation> annotation in mapView.annotations) {
        if([annotation isKindOfClass:[M5PlacemarkAnnotation class]])
            [mapView removeAnnotation:annotation];
    }
    
    M5PlacemarkAnnotation *annotation = [[M5PlacemarkAnnotation alloc] initWithPlacemark:placemark];
    [mapView addAnnotation:annotation];
    [mapView selectAnnotation:annotation animated:YES];
}

-(NSString *)stringWithShortTimeSince:(NSDate *)date
{
    CFTimeInterval now = [[NSDate date] timeIntervalSince1970];
    CFTimeInterval then = [date timeIntervalSince1970];
    
    CFTimeInterval diff = MAX(1, now - then);
    
    if(diff < 60)
        return @"seconds ago";
    else if(diff < 60 * 60) {
        int mins = (int)(diff / 60.0);
        return [NSString stringWithFormat:@"%i minute%@ ago", mins, mins > 1 ? @"s" : @""];
    }
    else if(diff < 60 * 60 * 24) {
        int hrs = (int)(diff / (60.0 * 60.0));
        return [NSString stringWithFormat:@"%i hour%@ ago", hrs, hrs > 1 ? @"s" : @""];
    }
    
    int days = (int)(diff / (60.0 * 60.0 * 24.0));
    return [NSString stringWithFormat:@"%i day%@ ago", days, days > 1 ? @"s" : @""];
}

@end
