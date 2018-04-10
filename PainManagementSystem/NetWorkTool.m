//
//  NetWorkTool.m
//  P06A
//
//  Created by Binger Zeng on 2018/2/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "NetWorkTool.h"

@interface NetWorkTool()

@end

@implementation NetWorkTool
static NetWorkTool *_instance;

+(instancetype)sharedNetWorkTool{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[NetWorkTool alloc]initWithBaseURL:nil];
        _instance.requestSerializer = [AFJSONRequestSerializer serializer];
        
        //设置请求的超时时间
        [_instance.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _instance.requestSerializer.timeoutInterval = 20.f;
        [_instance.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        
        _instance.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
//
//        _instance.responseSerializer = [AFHTTPResponseSerializer serializer];
    });
    return _instance;
}

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
    
    //发送的参数
//    NSLog(@"dic = %@",params);
    
    
    
    //打开状态栏的风火轮
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [self POST:address
    parameters:params
      progress:^(NSProgress * _Nonnull uploadProgress) {
          
      }
       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           
           //请求结果出现后关闭风火轮
           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
           
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
           //请求结果出现后关闭风火轮
           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
           
           NSLog(@"task = %@",task);
           
           NSLog(@"error = %@",error.localizedDescription);
           dispatch_async(dispatch_get_main_queue(), ^{
               [SVProgressHUD showErrorWithStatus:error.localizedDescription];
               
               
               
           });
       }];
}

@end
