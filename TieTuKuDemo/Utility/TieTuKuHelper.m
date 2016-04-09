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



+(instancetype)helper
{
    return [[[self class] alloc] init];
}

// 单例
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    static TieTuKuHelper* helper = nil;
    dispatch_once(&onceToken, ^{
        if (!helper) {
            helper = [[super alloc] init];
        }
    });
    return helper;
}
-(instancetype)init
{

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


-(NSURLSessionDataTask *)fetchTieTuKuCategoryWithCompletionHandler:(void (^)(NSArray<NSDictionary *> *categories,NSError* error))completionHandler
{
    NSString *urlString=[NSString stringWithFormat:@"getcatalog?key=%@&returntype=json",TieTuKuOpenKey];

    return [self.HTTPSessionManager GET:urlString
                      parameters:nil
                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                             if ([responseObject isKindOfClass:[NSArray class]]) {
                                 completionHandler(responseObject,nil);
                             }
                         }
                        failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                            completionHandler(nil,error);
                        }];

}

-(NSURLSessionDataTask *)fetchRandomRecommendedPhotoURLWithCompletionHandler:(void (^)(NSArray<NSString *> *urlStrings,NSError* error))completionHandler
{
    NSString *urlString=[NSString stringWithFormat:@"getrandrec?key=%@&returntype=json",TieTuKuOpenKey];

   return  [self.HTTPSessionManager GET:urlString
                      parameters:nil
                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

                             if ([responseObject isKindOfClass:[NSArray class]]) {
                                 NSArray *randomPhotos = (NSArray *)responseObject;
                                 completionHandler([randomPhotos valueForKey:@"linkurl"],nil);
                             }
                             // randomPhotos is an array of dictionay which has a linkurl key which value is the Photo url

                         }
                         failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                             completionHandler(nil,error);
                         }];

}

-(NSURLSessionDataTask *)fetchPhotoURLsOfCategory:(NSInteger)categoryID
                      pageIndex:(NSInteger)index
              completionHandler:(void (^)(NSArray<NSString *> *urlStrings,NSError* error))completionHandler
{
    NSString *urlString = nil;
    NSInteger pageIndex = index < 1 ? 1 : index;

    if (categoryID > 0)
    {
        urlString = [NSString stringWithFormat:@"getnewpic?key=%@&returntype=json&p=%ld&cid=%ld",TieTuKuOpenKey,(long)pageIndex,(long)categoryID];
    }else
    {
        urlString = [NSString stringWithFormat:@"getnewpic?key=%@&returntype=json&p=%ld&cid=1",TieTuKuOpenKey,(long)pageIndex];
    }

   return [self.HTTPSessionManager GET:urlString
                            parameters:nil
                               success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                                   if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                       NSArray *pics = [((NSDictionary *)responseObject) valueForKey:@"pic"];
                                       completionHandler([pics valueForKey:@"linkurl"],nil);
                                   }
                                }
                               failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                                   completionHandler(nil,error);
                               }];
}

-(NSURLSessionDataTask *)fetchImageAtURLString:(NSString *)urlString
      completionHandle:(void (^)(UIImage * image,NSError* error))completionHandler{

   return [self.HTTPSessionManager GET:urlString
                      parameters:nil
                         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                             NSError * error = nil;
                             if ([responseObject isKindOfClass:[UIImage class]]) {
                                 completionHandler(responseObject,error);
                             }
                            }
                         failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                             completionHandler(nil,error);
                         }];
}

@end
