//
//  M5CategoriesController.m
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "M5CategoriesController.h"

@interface M5CategoriesController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate> {
    NSArray *categories;
    UISearchDisplayController *searchController;
    NSArray *filteredCategories;
    UIImage *blankImage;
}

-(IBAction)cancelButtonTapped:(id)sender;
-(IBAction)noFilterButtonTapped:(id)sender;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end


@implementation M5CategoriesController

@synthesize searchBar;
@synthesize tableView;
@synthesize delegate;

-(id)initWithCategories:(NSArray *)theCategories
{
    self = [super initWithNibName:@"M5CategoriesController" bundle:nil];
    if (self) {
        categories = theCategories;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchController.delegate = self;
    searchController.searchResultsDataSource = self;
    searchController.searchResultsDelegate = self;
}

-(void)viewDidUnload
{
    [self setSearchBar:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction)cancelButtonTapped:(id)sender {
    [self.delegate categoriesControllerDidCancel:self];
}

- (IBAction)noFilterButtonTapped:(id)sender {
    [self.delegate categoriesController:self didSelectCategory:nil];
}

#pragma mark - UITableViewDataSource and UITableViewDelegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    if(theTableView == searchController.searchResultsTableView)
        return filteredCategories.count;
    else
        return categories.count;
}

-(UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    M5VenueCategory *category;
    
    if(theTableView == searchController.searchResultsTableView)
        category = [filteredCategories objectAtIndex:indexPath.row];
    else
        category = [categories objectAtIndex:indexPath.row];
    
    cell.textLabel.text = category.name;
    if(category.parentCategory) {
        if(category.subcategories)
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Parent category: %@; %u subcategories", category.parentCategory.name, category.subcategories.count];
        else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Parent category: %@", category.parentCategory.name];
    }
    else
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Root category; %u subcategories", category.subcategories.count];
    
    return cell;
}

-(void)tableView:(UITableView *)theTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    M5VenueCategory *category;
    
    if(theTableView == searchController.searchResultsTableView)
        category = [filteredCategories objectAtIndex:indexPath.row];
    else
        category = [categories objectAtIndex:indexPath.row];
    
    [cell.imageView setImageWithURL:category.iconURL placeholderImage:[UIImage imageNamed:@"blank.png"]];
}

-(void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    M5VenueCategory *category;
    if(theTableView == searchController.searchResultsTableView)
        category = [filteredCategories objectAtIndex:indexPath.row];
    else
        category = [categories objectAtIndex:indexPath.row];
    
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
        M5VenueCategory *category = [((theTableView == searchController.searchResultsTableView) ? filteredCategories : categories) objectAtIndex:indexPath.row];
        [UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%@ - %@", category.name, category._id];
    }
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
