//
//  TieTuKuImageViewController.m
//  TieTuKuDemo
//
//  Created by Amay on 10/26/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "TieTuKuImageViewController.h"
@interface TieTuKuImageViewController()<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) UIImageView * imageView;

@end


@implementation TieTuKuImageViewController

-(void)viewDidLoad{

    [self configureScrollView];

    self.navigationController.hidesBarsOnSwipe=YES;

}


- (void)configureScrollView {

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = self.image;
    [self.scrollView addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView = imageView;

    self.scrollView.contentSize = self.view.bounds.size;
    self.imageView.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);

    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.delegate = self;

}
-(void)setImage:(UIImage *)image{
    _image = image;
    self.imageView.image = image;
}

#pragma mark - ScrollViewDelegate
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}
@end
