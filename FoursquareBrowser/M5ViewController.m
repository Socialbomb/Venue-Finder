//
//  M5ViewController.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "M5ViewController.h"
#import "M5FoursquareClient.h"
#import <MapKit/MapKit.h>
#import "M5CategoriesController.h"
#import "M5VenueViewController.h"

typedef enum {
    M5AlertCategoryError
} M5AlertType;

@interface M5ViewController () <MKMapViewDelegate, UIAlertViewDelegate, M5CategoriesControllerDelegate> {
    M5AlertType currentAlert;
    NSArray *flattenedCategories;
    M5VenueCategory *currentCategory;
    BOOL didAppear;
}

@property (weak, nonatomic) IBOutlet UILabel *categoryName;
@property (weak, nonatomic) IBOutlet UIView *refreshContainer;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *currentCategoryName;

-(IBAction)categoryButtonTapped:(id)sender;
-(IBAction)refreshButtonTapped:(id)sender;

-(void)loadCategories;
-(void)refreshVenues;

-(void)showRefreshButton;
-(void)hideRefreshButton;

-(void)removeAllAnnotations;

@end


@implementation M5ViewController

@synthesize mapView;
@synthesize currentCategoryName;
@synthesize categoryName;
@synthesize refreshContainer;

#pragma mark - View Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
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
    [self setCategoryName:nil];
    [self setRefreshContainer:nil];
    [self setMapView:nil];
    [self setCurrentCategoryName:nil];
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

#pragma mark - MKMapViewDelegate

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self showRefreshButton];
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
    
    currentAlert = -1;
}

#pragma mark - Guts

-(void)loadCategories
{
    [self showHUDFromViewWithText:@"Loading" details:@"fetching categories" dimScreen:YES];
    [[M5FoursquareClient sharedClient] getVenueCategoriesWithCompletion:^(NSArray *theCategories) {
        flattenedCategories = theCategories;
        
        [self hideAllHUDsFromView];
        
        [self refreshVenues];
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
                                                    [self hideRefreshButton];
                                                    
                                                    [self removeAllAnnotations];
                                                    
                                                    for(M5Venue *venue in venues)
                                                        [mapView addAnnotation:venue];
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

#pragma mark - M5CategoriesControllerDelegate

-(void)categoriesController:(M5CategoriesController *)categoriesController didSelectCategory:(M5VenueCategory *)category
{
    if(!category)
        currentCategoryName.text = @"All categories";
    else
        currentCategoryName.text = category.name;
    
    [categoriesController dismissViewControllerAnimated:YES completion:^{
        if(currentCategory == category)
            return;
        
        currentCategory = category;
        
        [self refreshVenues];
    }];
}

-(void)categoriesControllerDidCancel:(M5CategoriesController *)categoriesController
{
    [categoriesController dismissModalViewControllerAnimated:YES];
}

#pragma mark - Utilities

-(void)showRefreshButton
{
    if(refreshContainer.alpha == 1) return;
    
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         refreshContainer.alpha = 1;
                         CGRect newFrame = refreshContainer.frame;
                         newFrame.origin.y = self.view.frame.size.height - newFrame.size.height;
                         refreshContainer.frame = newFrame;
                     } completion:NULL];
}

-(void)hideRefreshButton
{
    if(refreshContainer.alpha == 0) return;
    
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         refreshContainer.alpha = 0;
                         CGRect newFrame = refreshContainer.frame;
                         newFrame.origin.y = self.view.frame.size.height;
                         refreshContainer.frame = newFrame;
                     } completion:NULL];
}

-(void)removeAllAnnotations
{
    for(id<MKAnnotation> annotation in mapView.annotations) {
        if([annotation isKindOfClass:[M5Venue class]])
            [mapView removeAnnotation:annotation];
    }
}

@end
