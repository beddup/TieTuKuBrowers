//
//  TieTuKuHelper.m
//  TieTuKuDemo
//
//  Created by Amay on 10/25/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "Defines.h"
#import "TieTuKuHelper.h"
#import "AFHTTPSessionManager.h"

@interface TieTuKuHelper()

@property (strong, nonatomic) AFHTTPSessionManager *HTTPSessionManager;

@end


@implementation TieTuKuHelper

+(instancetype)helper{
    return [[[self class] alloc] init];
}

-(instancetype)init{
    self = [super init];
    if (self) {

        _HTTPSessionManager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:@"http://api.tietuku.com/v2/api"]];

        // configure the responseSerializer, because the data may be json or image
        AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        AFImageResponseSerializer *imageSerializer = [AFImageResponseSerializer serializer];
        
        AFCompoundResponseSerializer *compoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[jsonSerializer,imageSerializer]];
        _HTTPSessionManager.responseSerializer = compoundSerializer;

    }
    return self;
}


-(NSURLSessionDataTask *)fetchTieTuKuCategoryWithCompletionHandler:(void (^)(NSArray<NSDictionary *> *categories))completionHandler{

    NSString *urlString=[NSString stringWithFormat:@"getcatalog?key=%@&returntype=json",TieTuKuOpenKey];

    return [self.HTTPSessionManager GET:urlString
                      parameters:nil
                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                             completionHandler(responseObject);
                         }
                         failure:nil];

}

-(NSURLSessionDataTask *)fetchRandomRecommendedPhotoURLWithCompletionHandler:(void (^)(NSArray<NSString *> *urlStrings))completionHandler{

    NSString *urlString=[NSString stringWithFormat:@"getrandrec?key=%@&returntype=json",TieTuKuOpenKey];

   return  [self.HTTPSessionManager GET:urlString
                      parameters:nil
                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                             NSArray *randomPhotos = (NSArray *)responseObject;
                             // randomPhotos is an array of dictionay which has a linkurl key which value is the Photo url
                             completionHandler([randomPhotos valueForKey:@"linkurl"]);
                         }
                         failure:nil];

}

-(NSURLSessionDataTask *)fetchPhotoURLsOfCategory:(NSInteger)categoryID
                      pageIndex:(NSInteger)index
              completionHandler:(void (^)(NSArray<NSString *> *urlStrings))completionHandler{

    NSString *urlString = nil;
    NSInteger pageIndex = index < 1 ? 1 : index;

    if (categoryID > 0) {
        urlString = [NSString stringWithFormat:@"getnewpic?key=%@&returntype=json&p=%d&cid=%d",TieTuKuOpenKey,pageIndex,categoryID];
    }else{
        urlString = [NSString stringWithFormat:@"getnewpic?key=%@&returntype=json&p=%d&cid=1",TieTuKuOpenKey,pageIndex];
    }

   return [self.HTTPSessionManager GET:urlString parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

        NSArray *pics = [((NSDictionary *)responseObject) valueForKey:@"pic"];
        completionHandler([pics valueForKey:@"linkurl"]);

    } failure:nil];
}

-(NSURLSessionDataTask *)fetchImageAtURLString:(NSString *)urlString
      completionHandle:(void (^)(UIImage * image))completionHandler{

   return [self.HTTPSessionManager GET:urlString
                      parameters:nil
                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                                completionHandler(responseObject);
                            }
                         failure:nil];
}

@end
