//
//  FavoritePhotos.h
//  
//
//  Created by Amay on 10/26/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface FavoritePhotos : NSManagedObject

// Insert code here to declare functionality of your managed object subclass
+(void)removeFavoritePhoto:(NSString *)urlString;

+(void)insertFavoritePhoto:(NSString *)urlString;

+(BOOL)isFavorite:(NSString *)urlString;

+(NSArray *)favoritePhotoURLStrings;

@end

NS_ASSUME_NONNULL_END

#import "FavoritePhotos+CoreDataProperties.h"
