//  M5CategoriesController.h
//  Copyright (c) 2012 Socialbomb.
//  This code is distributed under the terms and conditions of the MIT license.

#import <UIKit/UIKit.h>
#import "M5VenueCategory.h"

// The view controller that presents a list of venue categories to the user for selection.

@protocol M5CategoriesControllerDelegate;

@interface M5CategoriesController : UIViewController

@property (nonatomic, weak) id<M5CategoriesControllerDelegate> delegate;

// Create a new instance with the given array of M5VenueCategory objects.
// The array is assumed to be sorted using M5VenueCategory's -compare:.
-(id)initWithCategories:(NSArray *)theCategories;

@end


@protocol M5CategoriesControllerDelegate <NSObject>

@required
-(void)categoriesControllerDidCancel:(M5CategoriesController *)categoriesController;

// The category argument will be nil if the user selected the "No Filter" button.
-(void)categoriesController:(M5CategoriesController *)categoriesController didSelectCategory:(M5VenueCategory *)category;

@end