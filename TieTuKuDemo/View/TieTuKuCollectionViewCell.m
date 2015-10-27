//
//  TieTuKuCollectionViewCell.m
//  TieTuKuDemo
//
//  Created by Amay on 10/25/15.
//  Copyright © 2015 Beddup. All rights reserved.
//
#import "Defines.h"
#import "TieTuKuCollectionViewCell.h"
#import "DGActivityIndicatorView.h"
#import "FavoritePhotos.h"
#import "TieTuKuDemo-Swift.h"

@interface TieTuKuCollectionViewCell()

@property(weak, nonatomic) DGActivityIndicatorView *indicator;

@property(weak, nonatomic) UIImageView *imageView;

@property(weak, nonatomic) DOFavoriteButton *favoriteButton;

@end

@implementation TieTuKuCollectionViewCell

-(void)setImage:(UIImage *)image
{
    _image=image;
    if (image)
    {
        [self.indicator stopAnimating];
        self.indicator.hidden = YES;
        self.favoriteButton.hidden = NO;
    }
    self.imageView.image=image;
    [self layoutIfNeeded];
}

-(void)setImageURLString:(NSString *)urlString
{
    _imageURLString = urlString;

    // check whether it is favorite
    self.favoriteButton.selected = [FavoritePhotos isFavorite:urlString];
}

-(void)layoutSubviews
{
    self.imageView.frame = self.bounds;
    self.indicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.favoriteButton.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)-30);
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    self.image = nil;
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
}

#pragma  mark - setup
-(void)awakeFromNib
{
    [self setup];
}

-(void)setup
{
    self.backgroundColor = [UIColor darkGrayColor];

    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self addSubview: imageView];
    self.imageView = imageView;

    // add indicator
    DGActivityIndicatorView *indicator = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeNineDots tintColor:[UIColor whiteColor] size:50.0];
    [self addSubview:indicator];
    self.indicator = indicator;
    [self.indicator startAnimating];

    // add Favorite Button
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"star" ofType:@"png"];
    UIImage *image= [UIImage imageWithContentsOfFile:imagePath];
    DOFavoriteButton *favoriteButton = [[DOFavoriteButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44) image:image];
    favoriteButton.imageColorOff = [UIColor blackColor];
    [favoriteButton addTarget:self action:@selector(changeFavorite:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:favoriteButton];
    self.favoriteButton = favoriteButton;
    self.favoriteButton.hidden = YES;
}

-(void)changeFavorite:(DOFavoriteButton *)sender
{
    if (sender.selected)
    {
        [sender deselect];
        [FavoritePhotos removeFavoritePhoto:self.imageURLString];
    }else
    {
        [sender select];
        [FavoritePhotos insertFavoritePhoto:self.imageURLString];
    }
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}


@end
