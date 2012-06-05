//
//  M5VenueViewController.m
//  Venue Finder
//
//  Created by Tim Clem on 3/27/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import "M5VenueViewController.h"
#import "M5FoursquareClient.h"

typedef enum {
    M5VenueTableLocationSection = 0,
    M5VenueTableGeneralInfoSection,
    M5VenueTableStatsSection,
    M5VenueTableCategoriesSection,
    M5VenueTableTagsSection,
    M5VenueTableMetadataSection,
    M5VenueTableSectionCount
} M5VenueTableSection;


// Holder for properties of a cell.
@interface M5VenueCellData : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, assign) BOOL copyable;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) BOOL subtitleCellStyle;

-(id)initWithName:(NSString *)theName value:(NSString *)theValue copyable:(BOOL)copyable;
-(id)initWithName:(NSString *)theName value:(NSString *)theValue copyable:(BOOL)copyable target:(id)theTarget selector:(SEL)theSelector;

@end


@implementation M5VenueCellData

@synthesize name, value, copyable, target, selector, subtitleCellStyle;

-(id)initWithName:(NSString *)theName value:(NSString *)theValue copyable:(BOOL)copyableFlag target:(id)theTarget selector:(SEL)theSelector
{
    self = [super init];
    if(self) {
        self.name = theName;
        self.value = theValue;
        self.target = theTarget;
        self.selector = theSelector;
        self.copyable = copyableFlag;
    }
    
    return self;
}

-(id)initWithName:(NSString *)theName value:(NSString *)theValue copyable:(BOOL)copyableFlag
{
    self = [self initWithName:theName value:theValue copyable:copyableFlag target:nil selector:NULL];
    return self;
}

-(void)handleSelection:(NSIndexPath *)indexPath
{
    // The static analyzer freaks out about this under ARC because the selecter we
    // perform may have retain/release implications. In our cases it doesn't,
    // so we tell the analyzer to chill out:
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [target performSelector:selector withObject:self withObject:indexPath];
#pragma clang diagnostic pop
}

@end


@interface M5VenueViewController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
    M5Venue *venue;
    M5Venue *abbreviatedVenue;
    NSArray *cellDataBySection;
    NSArray *sectionTitles;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

-(void)foursquareButtonTapped:(id)sender;

-(void)loadVenue;
-(void)prepareData;
-(M5VenueCellData *)cellDataForIndexPath:(NSIndexPath *)indexPath;

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name value:(NSString *)value copyable:(BOOL)copyable target:(id)target selector:(SEL)selector;
-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name value:(NSString *)value copyable:(BOOL)copyable;
-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name value:(NSString *)value;
-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name ifValueNotNull:(NSString *)value copyable:(BOOL)copyable target:(id)target selector:(SEL)selector;
-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name ifValueNotNull:(NSString *)value copyable:(BOOL)copyable;
-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name ifValueNotNull:(NSString *)value;
-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name uintValue:(uint)value;

@end


@implementation M5VenueViewController

@synthesize tableView = _tableView;

-(id)initWithAbbreviatedVenue:(M5Venue *)theAbbreviatedVenue
{
    self = [super initWithNibName:@"M5VenueViewController" bundle:nil];
    if (self) {
        abbreviatedVenue = theAbbreviatedVenue;
        sectionTitles = [NSArray arrayWithObjects:@"Location", @"General Info", @"Stats", @"Categories", @"Tags", @"Metadata", nil];
        
        self.title = abbreviatedVenue.name;
        
        UIButton *foursquareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        foursquareButton.frame = CGRectMake(0, 0, 30, 30);
        [foursquareButton setImage:[UIImage imageNamed:@"foursquare-icon-36x36.png"] forState:UIControlStateNormal];
        [foursquareButton addTarget:self action:@selector(foursquareButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:foursquareButton];
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadVenue];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // If we're still trying to load the venue, cancel that request
    if(!venue)
        [[M5FoursquareClient sharedClient] cancelGetOfVenueID:abbreviatedVenue.venueID];
}

-(void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Interaction

- (void)foursquareButtonTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:abbreviatedVenue.venueURL];
}

#pragma mark - Cell selection handlers

-(void)addressCellSelected:(M5VenueCellData *)cellData indexPath:(NSIndexPath *)indexPath
{
    NSString *llString = [NSString stringWithFormat:@"%.7f,%.7f", venue.location.coordinate.latitude, venue.location.coordinate.longitude];
    NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@&ll=%@", venue.name, llString];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

-(void)twitterCellSelected:(M5VenueCellData *)cellData indexPath:(NSIndexPath *)indexPath
{
    NSString *urlString = [NSString stringWithFormat:@"http://twitter.com/%@", venue.twitterHandle];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

-(void)phoneCellSelected:(M5VenueCellData *)cellData indexPath:(NSIndexPath *)indexPath
{
    NSString *urlString = [NSString stringWithFormat:@"tel:%@", venue.phoneNumber ? venue.phoneNumber : venue.formattedPhoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

#pragma mark - Data stuff

-(void)loadVenue
{
    // Not blocking; the user can back out while this is loading (in which case we stop the request;
    // see -viewWillDisappear:).
    [self showHUDFromViewWithText:@"Loading" details:@"fetching venue" dimScreen:NO];
    
    [[M5FoursquareClient sharedClient] getVenueWithID:abbreviatedVenue.venueID completion:^(M5Venue *fullVenue) {
        [self hideAllHUDsFromView];
        
        venue = fullVenue;
        
        [self prepareData];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self hideAllHUDsFromView];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Yikes!"
                                                        message:@"There was an error loading venue details. Try again, or visit the foursquare™ page?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Retry", @"foursquare™ page", nil];

        [alert show];
    }];
}

-(void)prepareData
{
    NSMutableArray *locationData = [NSMutableArray array];
    [self addCellDataToArray:locationData name:@"Address" ifValueNotNull:venue.location.streetAddress copyable:YES target:self selector:@selector(addressCellSelected:indexPath:)];
    [self addCellDataToArray:locationData name:@"City" ifValueNotNull:venue.location.city copyable:YES target:self selector:@selector(addressCellSelected:indexPath:)];
    [self addCellDataToArray:locationData name:@"State" ifValueNotNull:venue.location.state copyable:YES target:self selector:@selector(addressCellSelected:indexPath:)];
    [self addCellDataToArray:locationData name:@"Country" ifValueNotNull:venue.location.country copyable:YES target:self selector:@selector(addressCellSelected:indexPath:)];
    [self addCellDataToArray:locationData name:@"GPS" value:[NSString stringWithFormat:@"%.7f, %.7f", venue.location.coordinate.latitude, venue.location.coordinate.longitude] copyable:YES target:self selector:@selector(addressCellSelected:indexPath:)];
    
    NSMutableArray *infoData = [NSMutableArray array];
    [self addCellDataToArray:infoData name:@"Description" ifValueNotNull:venue.venueDescription copyable:YES];
    [self addCellDataToArray:infoData name:@"Twitter" ifValueNotNull:venue.twitterHandle copyable:YES target:self selector:@selector(twitterCellSelected:indexPath:)];
    [self addCellDataToArray:infoData name:@"Phone" ifValueNotNull:venue.formattedPhoneNumber ? venue.formattedPhoneNumber : venue.phoneNumber copyable:YES target:self selector:@selector(phoneCellSelected:indexPath:)];
    
    NSMutableArray *statsData = [NSMutableArray array];
    [self addCellDataToArray:statsData name:@"Here Now" uintValue:venue.stats.currentCheckinCount];
    [self addCellDataToArray:statsData name:@"Checkins" uintValue:venue.stats.totalCheckins];
    [self addCellDataToArray:statsData name:@"Users" uintValue:venue.stats.totalUsers];
    [self addCellDataToArray:statsData name:@"Total Tips" uintValue:venue.stats.totalTips];
    
    NSMutableArray *categoryData = [NSMutableArray arrayWithCapacity:venue.categories.count];
    for(M5VenueCategory *category in venue.categories) {
        M5VenueCellData *data = [[M5VenueCellData alloc] initWithName:category.name value:category.relationshipsDescription copyable:NO];
        data.subtitleCellStyle = YES;
        [categoryData addObject:data];
    }
    
    NSMutableArray *tagData = [NSMutableArray arrayWithCapacity:venue.tags.count];
    for(NSString *tag in venue.tags) {
        M5VenueCellData *data = [[M5VenueCellData alloc] initWithName:tag value:nil copyable:NO];
        data.subtitleCellStyle = YES;
        [tagData addObject:data];
    }
    
    NSMutableArray *metadataData = [NSMutableArray array];
    [self addCellDataToArray:metadataData name:@"ID" value:venue.venueID copyable:YES];
    if(venue.createdAt) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
        [self addCellDataToArray:metadataData name:@"Created" value:[formatter stringFromDate:venue.createdAt]];
    }
    [self addCellDataToArray:metadataData name:@"Verified" value:venue.verified ? @"Yes" : @"No"];
    
    cellDataBySection = [NSArray arrayWithObjects:locationData, infoData, statsData, categoryData, tagData, metadataData, nil];
}

-(M5VenueCellData *)cellDataForIndexPath:(NSIndexPath *)indexPath
{
    return [[cellDataBySection objectAtIndex:(NSUInteger)indexPath.section] objectAtIndex:(NSUInteger)indexPath.row];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // The API error dialog; options are to cancel, retry, or load the venue web page
    
    if(buttonIndex == alertView.cancelButtonIndex)
        [self dismissModalViewControllerAnimated:YES];
    else if(buttonIndex == alertView.firstOtherButtonIndex)
        [self loadVenue];
    else {
        [[UIApplication sharedApplication] openURL:abbreviatedVenue.venueURL];
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDelegate and UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(!venue) return 0;
    
    return M5VenueTableSectionCount;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!venue) return 0;
    
    return (NSInteger)[[cellDataBySection objectAtIndex:(NSUInteger)section] count];
}

-(UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!venue) return nil;
    
    M5VenueCellData *data = [self cellDataForIndexPath:indexPath];
    NSString *reuseIdentifier = data.subtitleCellStyle ? @"SubtitleCell" : @"Cell";
    
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(!cell) {
        UITableViewCellStyle cellStyle = data.subtitleCellStyle ? UITableViewCellStyleSubtitle : UITableViewCellStyleValue2;
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:reuseIdentifier];
    }
    
    cell.textLabel.text = data.name;
    cell.detailTextLabel.text = data.value;
    
    // Selectable if the cell data has an action associated with it.
    cell.selectionStyle = (data.target && data.selector) ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([[cellDataBySection objectAtIndex:(NSUInteger)section] count] == 0)
        return nil;
    
    return [sectionTitles objectAtIndex:(NSUInteger)section];
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if(action == @selector(copy:) && [self cellDataForIndexPath:indexPath].copyable)
        return YES;
    
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if(action == @selector(copy:))
        [UIPasteboard generalPasteboard].string = [self cellDataForIndexPath:indexPath].value;
}

-(void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    M5VenueCellData *data = [self cellDataForIndexPath:indexPath];
    [data handleSelection:indexPath];
    
    // Momentary selection...
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Utilities

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name value:(NSString *)value copyable:(BOOL)copyable target:(id)target selector:(SEL)selector
{
    M5VenueCellData *data = [[M5VenueCellData alloc] initWithName:name value:value copyable:copyable target:target selector:selector];
    [array addObject:data];
}

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name value:(NSString *)value copyable:(BOOL)copyable
{
    [self addCellDataToArray:array name:name value:value copyable:copyable target:nil selector:NULL];
}

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name value:(NSString *)value
{
    M5VenueCellData *data = [[M5VenueCellData alloc] initWithName:name value:value copyable:NO];
    [array addObject:data];
}

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name ifValueNotNull:(NSString *)value copyable:(BOOL)copyable target:(id)target selector:(SEL)selector
{
    if(value)
        [self addCellDataToArray:array name:name value:value copyable:copyable target:target selector:selector];
}

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name ifValueNotNull:(NSString *)value copyable:(BOOL)copyable
{
    [self addCellDataToArray:array name:name ifValueNotNull:value copyable:copyable target:nil selector:NULL];
}

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name ifValueNotNull:(NSString *)value
{
    if(value)
        [self addCellDataToArray:array name:name value:value];
}

-(void)addCellDataToArray:(NSMutableArray *)array name:(NSString *)name uintValue:(uint)value
{
    [self addCellDataToArray:array name:name value:[NSString stringWithFormat:@"%u", value]];
}

@end
