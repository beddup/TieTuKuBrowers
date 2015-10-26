//
//  FavoritePhotos+CoreDataProperties.h
//  
//
//  Created by Amay on 10/26/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "FavoritePhotos.h"

NS_ASSUME_NONNULL_BEGIN

@interface FavoritePhotos (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *urlString;
@property (nullable, nonatomic, retain) NSDate *likeDate;

@end

NS_ASSUME_NONNULL_END
