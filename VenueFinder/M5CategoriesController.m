//
//  M5CategoriesController.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import "M5CategoriesController.h"

@interface M5CategoriesController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate> {
    NSArray *categories;
    NSArray *filteredCategories;
    UIImage *blankImage;
    
    NSMutableArray *categoriesBySection;
    NSArray *sectionIndexTitles;
}

-(void)cancelButtonTapped:(id)sender;
-(void)noFilterButtonTapped:(id)sender;

-(M5VenueCategory *)categoryForIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)theTableView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end


@implementation M5CategoriesController

@synthesize tableView;
@synthesize delegate;

-(id)initWithCategories:(NSArray *)theCategories
{
    self = [super initWithNibName:@"M5CategoriesController" bundle:nil];
    if (self) {
        categories = theCategories;
        blankImage = [UIImage imageNamed:@"blank.png"];
        
        sectionIndexTitles = [NSArray arrayWithObjects:
                              UITableViewIndexSearch,  // Magic!
                              @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", 
                              @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", 
                              @"Y", @"Z", @"#", nil];
        
        categoriesBySection = [NSMutableArray arrayWithCapacity:27];
        for(uint i = 0; i < 27; i++)
            [categoriesBySection addObject:[NSMutableArray array]];
        
        for(M5VenueCategory *category in categories) {
            NSMutableArray *sectionArray = [categoriesBySection objectAtIndex:category.alphabetizationRank];
            [sectionArray addObject:category];
        }
        
        // Originally designed this with just a dummy UINavigationBar at the top, but it seems UISearchDisplayController
        // won't hide the nav bar on its searchContentsController unless it's inside a real UINavigationController...
        
        self.title = @"Categories";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelButtonTapped:)];

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"No Filter"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(noFilterButtonTapped:)];
        
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:42.0/255.0 green:91.0/255.0 blue:213.0/255.0 alpha:1.0];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Scroll the search bar offscreen
    tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
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

-(void)cancelButtonTapped:(id)sender
{
    [self.delegate categoriesControllerDidCancel:self];
}

-(void)noFilterButtonTapped:(id)sender
{
    [self.delegate categoriesController:self didSelectCategory:nil];
}

-(M5VenueCategory *)categoryForIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)theTableView
{
    if(theTableView == tableView)
        return [[categoriesBySection objectAtIndex:(NSUInteger)indexPath.section] objectAtIndex:(NSUInteger)indexPath.row];
    
    return [filteredCategories objectAtIndex:(NSUInteger)indexPath.row];  // Search results
}

#pragma mark - UITableViewDataSource and UITableViewDelegate

-(NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    if(theTableView == self.searchDisplayController.searchResultsTableView)
        return (NSInteger)filteredCategories.count;
    else {
        return (NSInteger)[[categoriesBySection objectAtIndex:(NSUInteger)section] count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    M5VenueCategory *category = [self categoryForIndexPath:indexPath inTableView:theTableView];
    
    cell.textLabel.text = category.name;
    cell.detailTextLabel.text = category.relationshipsDescription;
    
    return cell;
}

-(void)tableView:(UITableView *)theTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    M5VenueCategory *category = [self categoryForIndexPath:indexPath inTableView:theTableView];
    [cell.imageView setImageWithURL:category.iconURL placeholderImage:blankImage];
}

-(void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    M5VenueCategory *category = [self categoryForIndexPath:indexPath inTableView:theTableView];    
    [self.delegate categoriesController:self didSelectCategory:category];
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return action == @selector(copy:);
}

-(void)tableView:(UITableView *)theTableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if(action == @selector(copy:)) {
        M5VenueCategory *category = [self categoryForIndexPath:indexPath inTableView:theTableView];
        [UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%@ - %@", category.name, category._id];
    }
}

#pragma mark Section stuff in the non-search result table

-(NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView
{
    if(theTableView == tableView)
        return 27;  // A-Z, #
    
    return 1;  // The search results view
}

-(NSInteger)tableView:(UITableView *)theTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if(theTableView != tableView) {
        // The search results table view
        return NSNotFound;
    }
    
    if(index == 0) {
        // The search "section"
        [tableView setContentOffset:CGPointZero animated:NO];
        return NSNotFound;
    }
    
    return index - 1;
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)theTableView
{
    if(theTableView == tableView)
        return sectionIndexTitles;
    
    // No index in the search results view
    return nil;
}

#pragma mark - UISearchDisplayControllerDelegate

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    filteredCategories = [categories filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        M5VenueCategory *category = (M5VenueCategory *)evaluatedObject;
        if([category.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
           (category.parentCategory && [category.parentCategory.name rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))
        {
            return YES;
        }
           
       return NO;
    }]];
    
    return YES;
}

@end
