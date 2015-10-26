//
//  TieTuKuHelper.h
//  TieTuKuDemo
//
//  Created by Amay on 10/25/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TieTuKuHelper : NSObject

+(instancetype)helper;


/**
 * fetch the all categories asyn..ly, the result is a Array of Dictionary (@"cid":NSInterger,@"name":NSString)
 *
 *  @param completionHandler called when fetch completed;
 */
-(NSURLSessionDataTask *)fetchTieTuKuCategoryWithCompletionHandler:(void (^)(NSArray<NSDictionary *> *categories))completionHandler;



/**
 *  fetch random Recommended photos url, 30 photos
 *
 *  @param completionHandler called when fetch completed
 */

-(NSURLSessionDataTask *)fetchRandomRecommendedPhotoURLWithCompletionHandler:(void (^)(NSArray<NSString *> *urlStrings))completionHandler;



/**
 *  fetch photos url at some page of some category(NOTE:each page have 30 photos urls)
 *
 *  @param categoryID        ID of a category
 *  @param index             which page, 0 mean all pages.
 *  @param completionHandler called when fetch completed
 */
-(NSURLSessionDataTask *)fetchPhotoURLsOfCategory:(NSInteger)categoryID
                                        pageIndex:(NSInteger)index
                                completionHandler:(void (^)(NSArray<NSString *> *urlStrings))completionHandler;



/**
 *  fetch photo at url
 *
 *  @param url               the url that has the image
 *  @param completionHandler called when fetch completed
 */
-(NSURLSessionDataTask *)fetchImageAtURLString:(NSString *)urlString
                              completionHandle:(void (^)(UIImage * image))completionHandler;

@end
