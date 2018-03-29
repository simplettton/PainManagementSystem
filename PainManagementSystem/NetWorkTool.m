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

-(void)POST:(NSString *)address
 parameters:(NSDictionary *)parameters
   hasToken:(bool)hasToken
   progress:(void (^)(NSProgress * _Nonnull))uploadProgress
    success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure{
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    NSString *token = [userDefault objectForKey:@"Token"];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    
    if( hasToken )
    {

        [param setValue:token forKey:@"token"];
        
        [param setValue:parameters forKey:@"data"];
    }
    
    NetWorkTool *netWorkTool = [NetWorkTool sharedNetWorkTool];
    [netWorkTool POST:address
           parameters:param
             hasToken:hasToken progress:^(NSProgress * _Nonnull progress) {
                 uploadProgress(progress);
             } success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
                 success(task,response);
             } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                 failure(task,error);
             }];
    
}
@end
