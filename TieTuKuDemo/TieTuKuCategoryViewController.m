
//
//  TieTuKuCategoryViewController.m
//  TieTuKuDemo
//
//  Created by Amay on 10/26/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "TieTuKuCategoryViewController.h"

@implementation TieTuKuCategoryViewController


#pragma mark - UITableViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"category";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.text = [self.categories[indexPath.row] valueForKey:@"name"];
    return cell;
}

#pragma mark - UITableViewDelegate
#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCategory = self.categories[indexPath.row];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"categorySelected"])
    {
        self.selectedCategory = self.categories[self.tableView.indexPathForSelectedRow.row];
    }
}



@end
