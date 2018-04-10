//
//  NetWorkTool.m
//  P06A
//
//  Created by Binger Zeng on 2018/2/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "NetWorkTool.h"

@implementation NetWorkTool
static NetWorkTool *_instance;

+(instancetype)sharedNetWorkTool{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[NetWorkTool alloc]initWithBaseURL:nil];
        _instance.requestSerializer = [AFJSONRequestSerializer serializer];
        
        _instance.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
//
//        _instance.responseSerializer = [AFHTTPResponseSerializer serializer];
    });
    return _instance;
}

//-(void)POST:(NSString *)address
// parameters:(NSDictionary *)parameters
//   hasToken:(bool)hasToken
//    success:(void (^)(NSURLSessionDataTask * , id ))success
//    failure:(void (^)(NSURLSessionDataTask * , NSError *))failure{
//
//    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
//
//    NSString *token = [userDefault objectForKey:@"Token"];
//
//    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
//
//    if( hasToken )
//    {
//        [param setValue:token forKey:@"token"];
//    }
//
//
//    [param setValue:parameters forKey:@"data"];
//    NSDictionary *params = [param copy];
//
//    [self POST:address
//    parameters:params
//      progress:^(NSProgress * _Nonnull uploadProgress) {
//      }
//       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//           NSDictionary *jsonDict = responseObject;
//           if (jsonDict) {
//
//           }
//
//
//           success(task,responseObject);
//      }
//       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//           failure(task,error);
//       }];
//
//}
-(void)POST:(NSString *)address
     params:(NSDictionary *)parameters
   hasToken:(bool)hasToken
    success:(HttpResponseObject)responseBlock
    failure:(void (^)(NSURLSessionDataTask * , NSError *))failure{
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    NSString *token = [userDefault objectForKey:@"Token"];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    
    if( hasToken )
    {
        [param setValue:token forKey:@"token"];
    }
    
    
    [param setValue:parameters forKey:@"data"];
    NSDictionary *params = [param copy];
//    NSLog(@"dic = %@",params);
    
    [self POST:address
    parameters:params
      progress:^(NSProgress * _Nonnull uploadProgress) {
          
      }
       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           NSDictionary *jsonDict = responseObject;
           if (jsonDict != nil) {
               
               
               NSString *result = [jsonDict objectForKey:@"result"];
               NSDictionary *content = [jsonDict objectForKey:@"content"];
               NSString *errorString = [jsonDict objectForKey:@"msg"];
               
               
               HttpResponse* responseObject = [[HttpResponse alloc]init];
               responseObject.result = result;
               responseObject.content = content;
               responseObject.errorString = errorString;
               
               responseBlock(responseObject);
           }
       }
       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       }];
}

@end
