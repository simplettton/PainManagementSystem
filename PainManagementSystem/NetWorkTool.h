//
//  NetWorkTool.h
//  P06A
//
//  Created by Binger Zeng on 2018/2/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface NetWorkTool : AFHTTPSessionManager

+(instancetype)sharedNetWorkTool;

-(void)POST:(NSString *)address
 parameters:(NSDictionary *)parameters
   hasToken:(bool)hasToken
   progress:(void (^)(NSProgress * _Nonnull))uploadProgress
    success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;

@end
