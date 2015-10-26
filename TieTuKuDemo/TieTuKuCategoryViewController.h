//
//  TieTuKuCategoryViewController.h
//  TieTuKuDemo
//
//  Created by Amay on 10/26/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TieTuKuCategoryViewController : UITableViewController

@property(strong, nonatomic) NSArray *categories;

@property(nonatomic) NSDictionary *selectedCategory;

@end
