//
//  FavoritePhotos.m
//  
//
//  Created by Amay on 10/26/15.
//
//
#import "Defines.h"
#import "FavoritePhotos.h"
#import "FavoritePhotos+CoreDataProperties.h"

@implementation FavoritePhotos

// Insert code here to add functionality to your managed object subclass
+(void)removeFavoritePhoto:(NSString *)urlString{

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"FavoritePhotos"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"urlString == %@",urlString];
    NSArray * result = [CoreDateContext executeFetchRequest:fetchRequest error:NULL];
    for (FavoritePhotos *photo in result) {
        [CoreDateContext deleteObject:photo];
    }
}
+(void)insertFavoritePhoto:(NSString *)urlString{

    FavoritePhotos *favoritePhoto = [NSEntityDescription insertNewObjectForEntityForName:@"FavoritePhotos" inManagedObjectContext:CoreDateContext];
    favoritePhoto.likeDate = [NSDate date];
    favoritePhoto.urlString = urlString;
}

+(BOOL)isFavorite:(NSString *)urlString{

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"FavoritePhotos"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"urlString == %@",urlString];
    NSError *error = nil;
    NSArray * result = [CoreDateContext executeFetchRequest:fetchRequest error: &error];
    if (!error && result.count) {
        return YES;
    }
    return  NO;

}

+(NSArray *)favoritePhotoURLStrings{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"FavoritePhotos"];
    NSArray * result = [CoreDateContext executeFetchRequest:fetchRequest error:NULL];
    return [result valueForKey:@"urlString"];

}

@end
