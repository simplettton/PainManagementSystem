//
//  NetWorkTool.m
//  P06A
//
//  Created by Binger Zeng on 2018/2/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "NetWorkTool.h"
#import "MJRefresh.h"
#import "AppDelegate.h"
@interface NetWorkTool()

@end

@implementation NetWorkTool
static NetWorkTool *_instance;

+(instancetype)sharedNetWorkTool{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[NetWorkTool alloc]initWithBaseURL:nil];
        
        _instance.requestSerializer = [AFJSONRequestSerializer serializer];
        [_instance.requestSerializer setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

        //设置请求的超时时间
        [_instance.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _instance.requestSerializer.timeoutInterval = 3.f;
        [_instance.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        
        _instance.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
    });
    return _instance;
}

-(void)POST:(NSString *)address
     params:(id)parameters
   hasToken:(bool)hasToken
    success:(HttpResponseObject)responseBlock
    failure:(HttpFailureBlock)failureBlock{
    
    _instance.requestSerializer = [AFJSONRequestSerializer serializer];

    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    NSString *token = [userDefault objectForKey:@"Token"];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    
    id params;
    
    //通用token data模板
    if( hasToken )
    {
        [param setValue:token forKey:@"token"];
    }

    [param setValue:parameters forKey:@"data"];
    params = [param copy];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });

    
    [self POST:address
    parameters:params
      progress:^(NSProgress * _Nonnull uploadProgress) {
          
      }
       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           //请求结果出现后关闭风火轮
           
           dispatch_async(dispatch_get_main_queue(), ^{
               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
           });
 
           NSDictionary *jsonDict = responseObject;
           if (jsonDict != nil) {

               NSString *result = [jsonDict objectForKey:@"result"];
               NSNumber *count = [jsonDict objectForKey:@"count"];
               
               id content;
               //返回null的content
               if ([[jsonDict objectForKey:@"content"]isEqual:[NSNull null]]) {
                   content = nil;
               }else{
                   content = [jsonDict objectForKey:@"content"];
               }
               NSString *errorString = [jsonDict objectForKey:@"msg"];
               
               //token失效
               if ([errorString isEqualToString:@"无法识别的用户"]) {
                   [UserDefault setBool:NO forKey:@"IsLogined"];
                   [UserDefault synchronize];
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [SVProgressHUD showErrorWithStatus:@"账号验证过期，即将重新登录"];

                       AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                        [appDelegate performSelector:@selector(initRootViewController) withObject:nil afterDelay:1];
                    
                   });
               }else{
                   
                   HttpResponse* responseObject = [[HttpResponse alloc]init];
                   responseObject.result = result;
                   responseObject.content = content;
                   responseObject.errorString = errorString;
                   responseObject.count = count;
                   responseBlock(responseObject);
                   //停止刷新
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [self endTableViewRefreshing:NO];
                   });
               }

           }
       }
       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           //请求结果出现后关闭风火轮
           dispatch_async(dispatch_get_main_queue(), ^{
               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
           });
           if (failureBlock) {
               failureBlock(error);
           }

           dispatch_async(dispatch_get_main_queue(), ^{
               
               if ([error.localizedDescription hasSuffix:@"。"]) {

                   NSString *string = [error.localizedDescription substringToIndex:[error.localizedDescription length] -1];
//                   if (![string isEqualToString:@"请求超时"]) {
//                       [SVProgressHUD showErrorWithStatus:string];
                     [SVProgressHUD showErrorWithStatus:string];
//                   }
               }
               else{
                   [SVProgressHUD showErrorWithStatus:error.localizedDescription];
               }
               //endrefresh操作
               [self endTableViewRefreshing:YES];

           });
       }];
}
#pragma mark - private method

-(void)endTableViewRefreshing:(BOOL)includeFooter{
    
    UIViewController *controller = [self getCurrentVC];
    
    //当前控制器是导航控制器
    if ([[self getCurrentVC]isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *navi = (UINavigationController *)[self getCurrentVC];
        
        controller = [navi viewControllers][0];
    }
 
    [self traverseAllSubviews:controller.view includeFooter:includeFooter];
    
    
}

-(void)traverseAllSubviews:(UIView *)rootView includeFooter:(BOOL)includeFooter {
    for (UIView *subView in [rootView subviews])
    {
        if (!rootView.subviews.count) {
            return;
        }
        
        //如果是tableview 取消刷新
        if ([subView isKindOfClass:[UITableView class]]) {
            __weak UITableView *tableview = (UITableView *)subView;
            [tableview.mj_header endRefreshing];
            if (includeFooter) {
                [tableview.mj_footer endRefreshing];
            }

        }else if([subView isKindOfClass:[UICollectionView class]]){
            __weak UICollectionView *collectionview = (UICollectionView *)subView;
            [collectionview.mj_header endRefreshing];
            if (includeFooter) {
                [collectionview.mj_footer endRefreshing];
            }
            
        }
        [self traverseAllSubviews:subView includeFooter:includeFooter];
    }
}

//获取当前窗口控制器
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

-(void)POST:(NSString *)address
      image:(UIImage *)image
    success:(HttpResponseObject)responseBlock
    failure:(HttpFailureBlock)failureBlock{
    
    _instance.requestSerializer = [AFHTTPRequestSerializer serializer];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
    
//        NSData *data = UIImagePNGRepresentation(image);
    
    NSData *data = UIImageJPEGRepresentation(image, 0.8);
    
    [self POST:address
    parameters:data
      progress:^(NSProgress * _Nonnull uploadProgress) {
          
          [SVProgressHUD showProgress:uploadProgress.fractionCompleted status:@"正在存储照片中..."];
          NSLog(@"%f",uploadProgress.fractionCompleted);
      }
       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           //请求结果出现后关闭风火轮
           
           dispatch_async(dispatch_get_main_queue(), ^{
               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
           });
           
           NSDictionary *jsonDict = responseObject;
           if (jsonDict != nil) {
               
               NSString *result = [jsonDict objectForKey:@"result"];
               NSNumber *count = [jsonDict objectForKey:@"count"];
               
               id content;
               //返回null的content
               if ([[jsonDict objectForKey:@"content"]isEqual:[NSNull null]]) {
                   content = nil;
               }else{
                   content = [jsonDict objectForKey:@"content"];
               }
               NSString *errorString = [jsonDict objectForKey:@"msg"];
               
               //token失效
               if ([errorString isEqualToString:@"无法识别的用户"]) {
                   [UserDefault setBool:NO forKey:@"IsLogined"];
                   [UserDefault synchronize];
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [SVProgressHUD showErrorWithStatus:@"账号验证过期，即将重新登录"];
                       
                       AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                       [appDelegate performSelector:@selector(initRootViewController) withObject:nil afterDelay:1];
                       
                   });
               }else{
                   
                   HttpResponse* responseObject = [[HttpResponse alloc]init];
                   responseObject.result = result;
                   responseObject.content = content;
                   responseObject.errorString = errorString;
                   responseObject.count = count;
                   responseBlock(responseObject);
                   //停止刷新
                   dispatch_async(dispatch_get_main_queue(), ^{
                       [self endTableViewRefreshing:NO];
                   });
               }
           }
       }
       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           //请求结果出现后关闭风火轮
           dispatch_async(dispatch_get_main_queue(), ^{
               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
           });
           if (failureBlock) {
               failureBlock(error);
           }
           NSLog(@"error = %@",error);
           dispatch_async(dispatch_get_main_queue(), ^{
               
               if ([error.localizedDescription hasSuffix:@"。"]) {
                   
                   NSString *string = [error.localizedDescription substringToIndex:[error.localizedDescription length] -1];
                   //                   if (![string isEqualToString:@"请求超时"]) {
                   //                       [SVProgressHUD showErrorWithStatus:string];
                   [SVProgressHUD showErrorWithStatus:string];
                   //                   }
               }
               else{
                   [SVProgressHUD showErrorWithStatus:error.localizedDescription];

               }
               //endrefresh操作
               [self endTableViewRefreshing:YES];
               
           });
       }];
    
}
@end
