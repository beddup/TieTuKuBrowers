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

NSString *const MyFavorite = @"我的收藏";
NSString *const RandomPhotos = @"随便看看";

@interface TieTuKuPhotosCollectionViewController()<CHTCollectionViewDelegateWaterfallLayout,UIScrollViewDelegate>

// help to fetch photo urls and photos
@property (strong, nonatomic) TieTuKuHelper* helper;

@property (strong, nonatomic) NSArray* categories;
@property (nonatomic) NSDictionary* currentCategory;

@property (nonatomic) NSInteger maxPageIndex;//Indicate how far the user had fetched

// provide the all the url strings of images that are used in collection view
@property (strong, nonatomic) NSMutableOrderedSet *URLStrings;

// provide all the url string s and downloaded images to collection view (@"urlString":UIImage)
@property (strong, nonatomic) NSMutableDictionary *fetchedImages; //

// NSURLSessionDataTasks that are used to download images
@property (strong, nonatomic) NSMutableDictionary *dataTasks;

// load more UI
@property (weak, nonatomic) DGActivityIndicatorView *pullToRefreshIndicator;
@property (weak, nonatomic) UILabel *loadMoreLabel;

@end

@implementation TieTuKuPhotosCollectionViewController

#pragma mark - View Controller LifeCycle
-(void)viewDidLoad{

    [self configureCollectionView];
    self.navigationController.hidesBarsOnSwipe=YES;

    self.helper = [TieTuKuHelper helper];
    // Fetch the categories first, but set the rightBarButtonItem not enable before fetched
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.helper fetchTieTuKuCategoryWithCompletionHandler:^(NSArray<NSDictionary *> *categories) {
        NSDictionary *favorite = @{@"cid":@(-2),@"name":MyFavorite};
        NSDictionary *random = @{@"cid":@(-1),@"name":RandomPhotos};
        NSMutableArray *orderedCategory = [[categories sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *  _Nonnull obj1, NSDictionary *  _Nonnull obj2) {
            return [obj1[@"cid"] compare: obj2[@"cid"]];
        }] mutableCopy];

        [orderedCategory insertObject:random atIndex:0];
        [orderedCategory insertObject:favorite atIndex:0];
        self.categories = [orderedCategory copy];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }];

    // in default, 30 random photos will be displayed
    self.currentCategory = @{@"cid":@(-1),@"name":RandomPhotos};
}

-(void)viewDidLayoutSubviews{

    CGSize contentSize = self.collectionView.contentSize;
    self.loadMoreLabel.frame = CGRectMake(0, contentSize.height+20, contentSize.width, 30);
    self.pullToRefreshIndicator.center = CGPointMake(contentSize.width/2, CGRectGetMaxY(self.loadMoreLabel.frame)+30+30);

}

-(void)didReceiveMemoryWarning{
    //remove the images which are out of visible zone
    NSArray *rows= [[self.collectionView indexPathsForVisibleItems] valueForKey:@"row"];
    for (NSInteger i = 0 ; i < self.URLStrings.count; i++) {
        if (![rows containsObject:@(i)]) {
            NSString *urlString = self.URLStrings[i];
            [self.fetchedImages removeObjectForKey:urlString];
        }
    }
}


-(void)configureCollectionViewLayout{

    CHTCollectionViewWaterfallLayout *layout = (CHTCollectionViewWaterfallLayout *)self.collectionViewLayout;
    layout.columnCount = 3;
    layout.minimumContentHeight = 80.0;
}


-(void)configureCollectionView{
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


#pragma mark - Reset
/**
 *  clear all existing info, including urls, images and reset UI State
 *  called when category changes
 */
-(void)clear{

    for (NSString *taskURL in self.dataTasks) {
        [(NSURLSessionDataTask *)self.dataTasks[taskURL] cancel];
    }
    [self.dataTasks removeAllObjects];

    [self.URLStrings removeAllObjects];
    [self.fetchedImages removeAllObjects];

    self.maxPageIndex = 1;
    self.pullToRefreshIndicator.hidden = YES;
    self.loadMoreLabel.hidden = YES;
    [self.collectionView reloadData];

}


#pragma mark - Properties
-(NSArray *)categories{
    if (!_categories) {
        _categories = @[];
    }
    return _categories;
}

-(NSMutableOrderedSet *)URLStrings{
    if (!_URLStrings) {
        _URLStrings = [[NSMutableOrderedSet alloc]init];
    }
    return _URLStrings;
}

-(NSMutableDictionary *)fetchedImages{
    if (!_fetchedImages) {
        _fetchedImages = [@{} mutableCopy];
    }
    return _fetchedImages;
}

-(NSMutableDictionary *)dataTasks{
    if (!_dataTasks) {
        _dataTasks = [@{} mutableCopy];
    }
    return _dataTasks;
}

-(void)setCurrentCategory:(NSDictionary *)currentCategory{

    if ([currentCategory[@"name"] isEqualToString:_currentCategory[@"name"]]) {
        return;
    }
    _currentCategory = currentCategory;

    self.title = currentCategory[@"name"];

    //clear
    [self clear];
    self.navigationItem.leftBarButtonItem = nil;

    //fetch data
    if ([self.currentCategory[@"name"] isEqualToString:MyFavorite]) {

        // load photo from core data
        self.URLStrings = [NSMutableOrderedSet orderedSetWithArray:[FavoritePhotos favoritePhotoURLStrings]];
        [self.collectionView reloadData]; // image not fetched yet

    }else if ([self.currentCategory[@"name"] isEqualToString:RandomPhotos]){

        self.pullToRefreshIndicator.hidden = NO;
        UIBarButtonItem *changeRandomPhotos = [[UIBarButtonItem alloc] initWithTitle:@"换一批" style:  UIBarButtonItemStylePlain target:self action:@selector(changeRandomPhotos:)];
        self.navigationItem.leftBarButtonItem = changeRandomPhotos;

        [self.helper fetchRandomRecommendedPhotoURLWithCompletionHandler:^(NSArray<NSString *> *urlStrings) {
            self.URLStrings = [NSMutableOrderedSet orderedSetWithArray:urlStrings];
            self.pullToRefreshIndicator.hidden = YES;
            [self.collectionView reloadData]; // image not fetched yet
        }];

    }else{

        self.pullToRefreshIndicator.hidden = NO;
        [self.helper fetchPhotoURLsOfCategory:[self.currentCategory[@"cid"] integerValue] pageIndex:1 completionHandler:^(NSArray<NSString *> *urlStrings) {

            if (urlStrings.count >= 30){
                // no more photos
                self.loadMoreLabel.hidden = NO;
            }else{
                self.pullToRefreshIndicator.hidden = YES;
            }

            [self.URLStrings addObjectsFromArray:urlStrings];
            [self.collectionView reloadData]; // image not fetched yet
        }];
    }
}

-(void)changeRandomPhotos:(id)sender{

    [self clear];
    self.pullToRefreshIndicator.hidden = NO;
    [self.helper fetchRandomRecommendedPhotoURLWithCompletionHandler:^(NSArray<NSString *> *urlStrings) {

        self.pullToRefreshIndicator.hidden = YES;
        self.URLStrings = [NSMutableOrderedSet orderedSetWithArray:urlStrings];
        [self.collectionView reloadData]; // image not fetched yet

    }];
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return  self.URLStrings.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    TieTuKuCollectionViewCell *cell = (TieTuKuCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"TieTuKuPhotoCell" forIndexPath:indexPath];

    NSString *urlString = self.URLStrings[indexPath.row];
    cell.urlString = urlString;

    UIImage *fetchedImage = [self.fetchedImages valueForKey:urlString];

    if (fetchedImage) {
        // if loaded before, just use it
        cell.image = fetchedImage;

    }else{
        //otherwise try to load it
        if (!self.dataTasks[urlString]) {
            // fetch image
            NSURLSessionDataTask *datatask =  [self.helper fetchImageAtURLString:urlString completionHandle:^(UIImage *image) {

                    if ([[collectionView indexPathsForVisibleItems] containsObject:indexPath]) {
                        // if the cell is still visible, get it and give it an image
                        TieTuKuCollectionViewCell *theCell = (TieTuKuCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                        theCell.image = image;
                    }
                   [self.fetchedImages setObject:image forKey:urlString];
                   // when download done, remove task
                   [self.dataTasks removeObjectForKey:urlString];

                }];
            // store the task ,because it may be cancel later
            [self.dataTasks setObject:datatask forKey:urlString];
        }
    }
    return cell;

}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{

    // if change the category the URLStrings will be empty, check it first.
    if (self.URLStrings.count > indexPath.row) {

        NSString *urlString = self.URLStrings[indexPath.row];
        NSURLSessionDataTask *dataTask = self.dataTasks[urlString];

        // when end displaying , it is not much necessary to proceed the corresponding download
        [dataTask cancel];
        
        [self.dataTasks removeObjectForKey:urlString];

    }

}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

    NSString *urlString = self.URLStrings[indexPath.row];
    UIImage *fetchedImage = [self.fetchedImages valueForKey:urlString];
    [self performSegueWithIdentifier:@"showImage" sender:fetchedImage];
}

#pragma mark - CHTCollectionViewDelegateWaterfallLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
//    NSString *urlString=self.URLStrings[indexPath.row];
//    UIImage *image=[self.fetchedImages valueForKey:urlString];
//    if (image) {
//        return image.size;
//    }else{
        return CGSizeMake(120, 160);
//    }
}

#pragma  mark - UIScrollViewDelegate
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{


    if ([self.currentCategory[@"name"] isEqualToString:RandomPhotos]) {
        return;
    }
    if ([self.currentCategory[@"name"] isEqualToString:MyFavorite]) {
        return;
    }
    if (self.pullToRefreshIndicator.hidden) {
        return;
    }

    CGPoint point = scrollView.contentOffset;
    if (point.y > CGRectGetMaxY(self.pullToRefreshIndicator.frame)+50 - CGRectGetHeight(scrollView.bounds)){
        // time to load more photos
        NSString *indexString=[@(self.maxPageIndex) stringValue];
        if (!self.dataTasks[indexString]) {

            NSURLSessionDataTask *dataTask = [self.helper fetchPhotoURLsOfCategory:[self.currentCategory[@"cid"] integerValue] pageIndex:self.maxPageIndex+1 completionHandler:^(NSArray<NSString *> *urlStrings) {
                    if (urlStrings.count < 30) {
                        self.loadMoreLabel.hidden = YES;
                        self.pullToRefreshIndicator.hidden = YES;
                    }
                    [self.URLStrings addObjectsFromArray:urlStrings];
                    self.maxPageIndex++;
                    [self.collectionView reloadData]; // image not fetched yet
                    [self.dataTasks removeObjectForKey:indexString];
                }];
            [self.dataTasks setObject:dataTask forKey:indexString];
        }
    }
}
#pragma mark - navigation
//unwind
-(IBAction)categoryChanged:(UIStoryboardSegue *)segue{

    TieTuKuCategoryViewController *svc = (TieTuKuCategoryViewController *)segue.sourceViewController;
    self.currentCategory = svc.selectedCategory;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"showImage"]) {
        TieTuKuImageViewController *vc = (TieTuKuImageViewController *)segue.destinationViewController;
        vc.image = (UIImage *)sender;
    }else if ([segue.identifier isEqualToString:@"showCatefory"]){
        TieTuKuCategoryViewController *vc = (TieTuKuCategoryViewController *)segue.destinationViewController;
        vc.categories = self.categories;
    }
}


@end
