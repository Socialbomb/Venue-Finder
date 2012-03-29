//
//  M5ViewController.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "CLLocation+measuring.h"
#import "SBTableAlert.h"
#import "M5ViewController.h"
#import "M5FoursquareClient.h"
#import "M5CategoriesController.h"
#import "M5VenueViewController.h"

typedef enum {
    M5AlertCategoryError,
    M5AlertGoToLocation
} M5AlertType;

@interface M5ViewController () <MKMapViewDelegate, UIAlertViewDelegate, M5CategoriesControllerDelegate, SBTableAlertDataSource, SBTableAlertDelegate, UITextFieldDelegate> {
    M5AlertType currentAlert;
    NSArray *flattenedCategories;
    M5VenueCategory *currentCategory;
    BOOL didAppear;
    
    BOOL viewAlreadyLoaded;
    MKCoordinateRegion lastMapRegion;
    NSArray *lastMapVenues;
    
    UIAlertView *goAlert;
    NSArray *placemarks;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *currentCategoryName;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

-(IBAction)categoryButtonTapped:(id)sender;
-(IBAction)refreshButtonTapped:(id)sender;
-(IBAction)goButtonTapped:(id)sender;

-(void)loadCategories;
-(void)refreshVenues;
-(void)setCategoryLabelFromCategory:(M5VenueCategory *)category;

-(void)enableRefreshButtonAppropriately;

-(void)setMapVenues:(NSArray *)venues;
-(void)removeAllAnnotations;

-(CLRegion *)CLRegionWithMapRegion:(MKCoordinateRegion)region;
-(void)goToPlacemark:(CLPlacemark *)placemark;

@end


@implementation M5ViewController

@synthesize mapView;
@synthesize currentCategoryName;
@synthesize toolbar;
@synthesize refreshButton;

#pragma mark - View Lifecycle

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
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(!didAppear) {
        mapView.userTrackingMode = MKUserTrackingModeFollow;
        [self loadCategories];
    }
    
    didAppear = YES;
}

-(void)viewDidUnload
{
    [self setMapView:nil];
    [self setCurrentCategoryName:nil];
    [self setToolbar:nil];
    [self setRefreshButton:nil];
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Interaction

-(IBAction)categoryButtonTapped:(id)sender {
    M5CategoriesController *categoriesController = [[M5CategoriesController alloc] initWithCategories:flattenedCategories];
    categoriesController.delegate = self;
    [self presentModalViewController:categoriesController animated:YES];
}

-(IBAction)refreshButtonTapped:(id)sender {
    [self refreshVenues];
}

-(IBAction)goButtonTapped:(id)sender {
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

#pragma mark - MKMapViewDelegate

-(void)mapView:(MKMapView *)theMapView regionDidChangeAnimated:(BOOL)animated
{
    [self enableRefreshButtonAppropriately];
    lastMapRegion = mapView.region;
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
        else
            pin.annotation = annotation;
        
        return pin;
    }
    
    return nil;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    M5Venue *venue = (M5Venue *)view.annotation;

    M5VenueViewController *venueVC = [[M5VenueViewController alloc] initWithAbbreviatedVenue:venue];
    [self presentModalViewController:venueVC animated:YES];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(currentAlert == M5AlertCategoryError) {
        [self loadCategories];
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
    currentAlert = -1;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if(currentAlert == M5AlertGoToLocation)
        return [alertView textFieldAtIndex:0].text.length > 0;
    
    return YES;
}

#pragma mark - UITextFieldDelegate

// We are the delegate of the text field in the dialog box that comes up when you hit 'Go to...'
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [goAlert dismissWithClickedButtonIndex:goAlert.firstOtherButtonIndex animated:YES];
    return YES;
}

#pragma mark - Guts

-(void)setCategoryLabelFromCategory:(M5VenueCategory *)category
{
    if(!category)
        currentCategoryName.text = @"All categories";
    else
        currentCategoryName.text = category.name;
}

-(void)loadCategories
{
    [self showHUDFromViewWithText:@"Loading" details:@"fetching categories" dimScreen:YES];
    [[M5FoursquareClient sharedClient] getVenueCategoriesWithCompletion:^(NSArray *theCategories) {
        flattenedCategories = theCategories;
        
        [self hideAllHUDsFromView];
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
    [self showHUDFromViewWithText:@"Searching" details:@"finding venues" dimScreen:YES];
    [[M5FoursquareClient sharedClient] getVenuesOfCategory:currentCategory._id
                                               inMapRegion:mapView.region
                                                completion:^(NSArray *venues) {
                                                    [self hideAllHUDsFromView];
                                                    
                                                    [self setMapVenues:venues];
                                                    lastMapVenues = venues;
                                                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                    [self hideAllHUDsFromView];
                                                    
                                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ruh Roh!"
                                                                                                    message:@"Couldn't load venues! Try again later."
                                                                                                   delegate:nil
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
    return placemarks.count;
}

-(UITableViewCell *)tableAlert:(SBTableAlert *)tableAlert cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableAlert.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    CLPlacemark *placemark = [placemarks objectAtIndex:indexPath.row];
    
    if(placemark.name || placemark.thoroughfare) {
        cell.textLabel.text = placemark.name ? placemark.name : placemark.thoroughfare;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@, %@", placemark.locality, placemark.administrativeArea, placemark.country];
    }
    else if(placemark.locality) {
        cell.textLabel.text = placemark.locality;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", placemark.administrativeArea, placemark.country];
    }
    else {
        cell.textLabel.text = placemark.administrativeArea;
        cell.detailTextLabel.text = placemark.country;
    }
    
    return cell;
}

-(void)tableAlert:(SBTableAlert *)tableAlert didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLPlacemark *placemark = [placemarks objectAtIndex:indexPath.row];
    [self goToPlacemark:placemark];
}

#pragma mark - Utilities

-(void)enableRefreshButtonAppropriately
{
    refreshButton.enabled = [[M5FoursquareClient sharedClient] mapRegionIsOfSearchableArea:mapView.region];
}

-(void)removeAllAnnotations
{
    for(id<MKAnnotation> annotation in mapView.annotations) {
        if([annotation isKindOfClass:[M5Venue class]])
            [mapView removeAnnotation:annotation];
    }
}

-(CLRegion *)CLRegionWithMapRegion:(MKCoordinateRegion)region
{
    CLLocationCoordinate2D northEastCorner, southEastCorner;
    northEastCorner.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0);
    northEastCorner.longitude = region.center.longitude + (region.span.longitudeDelta / 2.0);
    southEastCorner.latitude = region.center.latitude  - (region.span.latitudeDelta  / 2.0);
    southEastCorner.longitude = northEastCorner.longitude;
    
    CLLocationDistance height = [CLLocation distanceFromCoordinate:northEastCorner toCoordinate:southEastCorner];
    
    return [[CLRegion alloc] initCircularRegionWithCenter:region.center radius:height identifier:@"GeocodingRegion"];
}

-(void)goToPlacemark:(CLPlacemark *)placemark
{
    if(placemark.region)
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(placemark.region.center, placemark.region.radius, placemark.region.radius) animated:YES];
    else
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(placemark.location.coordinate, 1000, 1000) animated:YES];
}

@end
