//
//  TieTuKuPhotosCollectionViewController.m
//  TieTuKuDemo
//
//  Created by Amay on 10/25/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "Defines.h"
#import "TieTuKuPhotosCollectionViewController.h"
#import "TieTuKuHelper.h"
#import "CHTCollectionViewWaterfallLayout.h"
#import "AFHTTPSessionManager.h"
#import "TieTuKuCollectionViewCell.h"
#import "DGActivityIndicatorView.h"
#import "TieTuKuImageViewController.h"
#import "TieTuKuCategoryViewController.h"
#import "FavoritePhotos.h"

NSString *const TTKMyFavorite = @"我的收藏";
NSString *const TTKRandomPhotos = @"随便看看";

@interface TieTuKuPhotosCollectionViewController()<CHTCollectionViewDelegateWaterfallLayout,UIScrollViewDelegate>

// help to fetch photo urls and photos
@property (strong, nonatomic) TieTuKuHelper* helper;

@property (strong, nonatomic) NSArray* categories;
@property (nonatomic) NSDictionary* currentCategory;

//Indicate how far the user had fetched
@property (nonatomic) NSInteger maxPageIndex;

// provide all the image url strings that are currently visible in collection view
@property (strong, nonatomic) NSMutableOrderedSet *URLStrings;

// provide all the image url strings and downloaded images (@"iamgeURLString":UIImage)
@property (strong, nonatomic) NSMutableDictionary *fetchedImages; //

// NSURLSessionDataTasks that are used to download images
@property (strong, nonatomic) NSMutableDictionary *dataTasks;

// load more UI
@property (weak, nonatomic) DGActivityIndicatorView *pullToRefreshIndicator;
@property (weak, nonatomic) UILabel *loadMoreLabel;

@end

@implementation TieTuKuPhotosCollectionViewController

#pragma mark - View Controller LifeCycle
-(void)viewDidLoad
{
    self.navigationController.hidesBarsOnSwipe=YES;

    [self configureCollectionView];

    self.helper = [TieTuKuHelper helper];

    [self fetchCategory];
}

-(void)fetchCategory{

    self.navigationItem.rightBarButtonItem.enabled = NO;
    // Fetch the categories first
    [self.helper fetchTieTuKuCategoryWithCompletionHandler:^(NSArray<NSDictionary *> *categories,NSError* error) {
        if (error) {
            [self showCannotGetPhonesAlert];
            return;
        }
        NSMutableArray *orderedCategory = [[categories sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *  _Nonnull obj1, NSDictionary *  _Nonnull obj2){

            return [obj1[@"cid"] compare: obj2[@"cid"]];

        }]mutableCopy];
        [orderedCategory insertObject:@{@"cid":@(-1),@"name":TTKRandomPhotos} atIndex:0];
        [orderedCategory insertObject:@{@"cid":@(-2),@"name":TTKMyFavorite} atIndex:0];

        self.categories = [orderedCategory copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem.enabled = YES;
        });

    }];

    // in default, 30 random photos will be displayed
    self.currentCategory = @{@"cid":@(-1),@"name":TTKRandomPhotos};

}
-(void)viewDidLayoutSubviews
{
    CGSize contentSize = self.collectionView.contentSize;
    self.loadMoreLabel.frame = CGRectMake(0, contentSize.height+20, contentSize.width, 30);
    self.pullToRefreshIndicator.center = CGPointMake(contentSize.width/2, CGRectGetMaxY(self.loadMoreLabel.frame)+30+30);
}

-(void)didReceiveMemoryWarning
{
    //remove the images which are out of visible zone
    NSArray *rows= [[self.collectionView indexPathsForVisibleItems] valueForKey:@"row"];
    for (NSInteger i = 0 ; i < self.URLStrings.count; i++)
    {
        if (![rows containsObject:@(i)])
        {
            NSString *urlString = self.URLStrings[i];
            [self.fetchedImages removeObjectForKey:urlString];
        }
    }
}

-(void)configureCollectionView
{
    [self configureCollectionViewLayout];

    //reused cell
    [self.collectionView registerClass:[TieTuKuCollectionViewCell class] forCellWithReuseIdentifier:@"TieTuKuPhotoCell"];

    // Configure pull to refreash UI
    UILabel *label = [[UILabel alloc] init];
    label.text = @"上拉加载更多";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    [self.collectionView addSubview: label];
    self.loadMoreLabel = label;

    DGActivityIndicatorView *indicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeNineDots tintColor:[UIColor whiteColor] size:60.0];
    [self.collectionView addSubview:indicator];
    self.pullToRefreshIndicator = indicator;
    [indicator startAnimating];
}

-(void)configureCollectionViewLayout
{
    CHTCollectionViewWaterfallLayout *layout = (CHTCollectionViewWaterfallLayout *)self.collectionViewLayout;
    layout.columnCount = 3;
    layout.minimumContentHeight = 80.0;
}

-(void)showCannotGetPhonesAlert{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"无法获取图片" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    });
}
#pragma mark - Reset

/**
 *  clear all existing info, including urls, images and reset UI State
 *  called when category changes
 */
-(void)clear
{
    [[self.dataTasks allValues] makeObjectsPerformSelector:@selector(cancel)];
    [self.dataTasks removeAllObjects];

    [self.URLStrings removeAllObjects];
    [self.fetchedImages removeAllObjects];

    self.maxPageIndex = 1;
    self.pullToRefreshIndicator.hidden = YES;
    self.loadMoreLabel.hidden = YES;
    [self.collectionView reloadData];
}

#pragma mark - Properties
-(NSArray *)categories
{
    if (!_categories)
    {
        _categories = @[];
    }
    return _categories;
}

-(NSMutableOrderedSet *)URLStrings
{
    if (!_URLStrings)
    {
        _URLStrings = [[NSMutableOrderedSet alloc]init];
    }
    return _URLStrings;
}

-(NSMutableDictionary *)fetchedImages
{
    if (!_fetchedImages)
    {
        _fetchedImages = [@{} mutableCopy];
    }
    return _fetchedImages;
}

-(NSMutableDictionary *)dataTasks
{
    if (!_dataTasks) {
        _dataTasks = [@{} mutableCopy];
    }
    return _dataTasks;
}

-(void)setCurrentCategory:(NSDictionary *)currentCategory
{
    if ([currentCategory[@"name"] isEqualToString:_currentCategory[@"name"]])
    {
        return;
    }
    _currentCategory = currentCategory;

    self.title = currentCategory[@"name"];

    //clear
    [self clear];
    self.navigationItem.leftBarButtonItem = nil;

    //fetch data
    if ([self.currentCategory[@"name"] isEqualToString:TTKMyFavorite])
    {
        // load photo from core data
        self.URLStrings = [NSMutableOrderedSet orderedSetWithArray:[FavoritePhotos favoritePhotoURLStrings]];
        [self.collectionView reloadData]; // image not fetched yet
    }
    else if ([self.currentCategory[@"name"] isEqualToString:TTKRandomPhotos])
    {
        self.pullToRefreshIndicator.hidden = NO;
        UIBarButtonItem *changeRandomPhotos = [[UIBarButtonItem alloc] initWithTitle:@"换一批"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self action:@selector(changeRandomPhotos:)];
        self.navigationItem.leftBarButtonItem = changeRandomPhotos;

        [self.helper fetchRandomRecommendedPhotoURLWithCompletionHandler:^(NSArray<NSString *> *urlStrings,NSError* error){

            if (error) {
                [self showCannotGetPhonesAlert];
                return;
            }

            self.URLStrings = [NSMutableOrderedSet orderedSetWithArray:urlStrings];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.pullToRefreshIndicator.hidden = YES;
                [self.collectionView reloadData]; // image not fetched yet
            });

        }];
    }else
    {
        self.pullToRefreshIndicator.hidden = NO;
        [self.helper fetchPhotoURLsOfCategory:[self.currentCategory[@"cid"] integerValue]
                                    pageIndex:1
                            completionHandler:^(NSArray<NSString *> *urlStrings,NSError* error) {
                                if (error) {
                                    [self showCannotGetPhonesAlert];
                                    return;
                                }
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (urlStrings.count >= 30)
                                    {
                                        // no more photos
                                        self.loadMoreLabel.hidden = NO;
                                    }
                                    else
                                    {
                                        self.pullToRefreshIndicator.hidden = YES;
                                    }

                                    [self.URLStrings addObjectsFromArray:urlStrings];
                                    [self.collectionView reloadData]; // image not fetched yet
                                });

        }];
    }
}

-(void)changeRandomPhotos:(id)sender
{

    [self clear];
    self.pullToRefreshIndicator.hidden = NO;
    [self.helper fetchRandomRecommendedPhotoURLWithCompletionHandler:^(NSArray<NSString *> *urlStrings,NSError* error) {
        if (error) {
            [self showCannotGetPhonesAlert];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.pullToRefreshIndicator.hidden = YES;
            self.URLStrings = [NSMutableOrderedSet orderedSetWithArray:urlStrings];
            [self.collectionView reloadData]; // image not fetched yet
        });
    }];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return  self.URLStrings.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TieTuKuCollectionViewCell *cell = (TieTuKuCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TieTuKuPhotoCell" forIndexPath:indexPath];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{

    NSString *urlString = self.URLStrings[indexPath.row];

    TieTuKuCollectionViewCell* tieTuKuCell = (TieTuKuCollectionViewCell*) cell;
    tieTuKuCell.imageURLString = urlString;

    // use the cached image; if no , load the image
    UIImage *fetchedImage = [self.fetchedImages valueForKey:urlString];
    if (fetchedImage)
    {
        tieTuKuCell.image = fetchedImage;
    }
    else
    {
        if (!self.dataTasks[urlString])
        {
            NSURLSessionDataTask *datatask =  [self.helper fetchImageAtURLString:urlString
                                                                completionHandle:^(UIImage *image,NSError* error) {
                if (error) {
                    [self showCannotGetPhonesAlert];
                    return;
                }

                if ([[collectionView indexPathsForVisibleItems] containsObject:indexPath])
                {
                    // if the cell is still visible, get it and give it an image
                    dispatch_async(dispatch_get_main_queue(), ^{
                        TieTuKuCollectionViewCell *theCell = (TieTuKuCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                        theCell.image = image;
                    });
                }
                [self.fetchedImages setObject:image forKey:urlString];
                [self.dataTasks removeObjectForKey:urlString];
                
            }];
            [self.dataTasks setObject:datatask forKey:urlString];
        }
    }
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    // when end displaying , it is not much necessary to proceed the corresponding download
    if (self.URLStrings.count > indexPath.row)
    {
        NSString *urlString = self.URLStrings[indexPath.row];
        NSURLSessionDataTask *dataTask = self.dataTasks[urlString];
        [dataTask cancel];
        [self.dataTasks removeObjectForKey:urlString];
    }

}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *urlString = self.URLStrings[indexPath.row];
    UIImage *fetchedImage = [self.fetchedImages valueForKey:urlString];
    [self performSegueWithIdentifier:@"showImage" sender:fetchedImage];
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(120, 160);
}

#pragma  mark - UIScrollViewDelegate
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.currentCategory[@"cid"] integerValue] < 0)
    {
        return;
    }
    if (self.pullToRefreshIndicator.hidden)
    {
        return;
    }
    CGPoint point = scrollView.contentOffset;

    // if drag to show the pullToRefreshIndicator, it should load more photos
    if (point.y > CGRectGetMaxY(self.pullToRefreshIndicator.frame)+50 - CGRectGetHeight(scrollView.bounds))
    {
        NSString *indexString=[@(self.maxPageIndex) stringValue];
        if (!self.dataTasks[indexString])
        {
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, 150, 0);
            NSURLSessionDataTask *dataTask = [self.helper fetchPhotoURLsOfCategory:[self.currentCategory[@"cid"] integerValue]
                                                                         pageIndex:self.maxPageIndex+1
                                                                 completionHandler:^(NSArray<NSString *> *urlStrings,NSError* error) {
                 if (error) {
                     [self showCannotGetPhonesAlert];
                     return;
                 }
                 dispatch_async(dispatch_get_main_queue(), ^{

                    if (urlStrings.count < 30)
                    {
                        // no more photos
                        self.loadMoreLabel.hidden = YES;
                        self.pullToRefreshIndicator.hidden = YES;
                    }
                    [self.URLStrings addObjectsFromArray:urlStrings];
                    self.maxPageIndex++;
                    scrollView.contentInset = UIEdgeInsetsZero;
                    scrollView.contentOffset = CGPointMake(point.x, point.y+150);
                    [self.collectionView reloadData]; // image not fetched yet
                    [self.dataTasks removeObjectForKey:indexString];
                 });
             }];
            [self.dataTasks setObject:dataTask forKey:indexString];
        }
    }
}

#pragma mark - navigation
//unwind
-(IBAction)categoryChanged:(UIStoryboardSegue *)segue
{
    TieTuKuCategoryViewController *svc = (TieTuKuCategoryViewController *)segue.sourceViewController;
    self.currentCategory = svc.selectedCategory;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showImage"])
    {
        TieTuKuImageViewController *vc = (TieTuKuImageViewController *)segue.destinationViewController;
        vc.image = (UIImage *)sender;
    }
    else if ([segue.identifier isEqualToString:@"showCatefory"])
    {
        TieTuKuCategoryViewController *vc = (TieTuKuCategoryViewController *)segue.destinationViewController;
        vc.categories = self.categories;
    }
}


@end
