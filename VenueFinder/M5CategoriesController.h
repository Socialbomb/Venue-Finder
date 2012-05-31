//
//  M5CategoriesController.h
//  FoursquareBrowser
//
//  Created by Tim Clem on 3/21/12.
//  Copyright (c) 2012 Socialbomb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "M5VenueCategory.h"

@protocol M5CategoriesControllerDelegate;


@interface M5CategoriesController : UIViewController

@property (nonatomic, weak) id<M5CategoriesControllerDelegate> delegate;

-(id)initWithCategories:(NSArray *)theCategories;

@end


@protocol M5CategoriesControllerDelegate <NSObject>

@required
-(void)categoriesControllerDidCancel:(M5CategoriesController *)categoriesController;
-(void)categoriesController:(M5CategoriesController *)categoriesController didSelectCategory:(M5VenueCategory *)category;

@end