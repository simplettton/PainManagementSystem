//
//  NetWorkTool.m
//  P06A
//
//  Created by Binger Zeng on 2018/2/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "NetWorkTool.h"
#import "MJRefresh.h"
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
        _instance.requestSerializer.timeoutInterval = 10.f;
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
               id content = [jsonDict objectForKey:@"content"];
               NSString *errorString = [jsonDict objectForKey:@"msg"];
               
               
               HttpResponse* responseObject = [[HttpResponse alloc]init];
               responseObject.result = result;
               responseObject.content = content;
               responseObject.errorString = errorString;
               

               responseBlock(responseObject);
               
               
               //停止刷新
               dispatch_async(dispatch_get_main_queue(), ^{
                   [self endTableViewHeaderRefreshing];
               });
           }
       }
       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           //请求结果出现后关闭风火轮

           [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;


           
           NSLog(@"task = %@",task);
           
           NSLog(@"error = %@",error);
           dispatch_async(dispatch_get_main_queue(), ^{
               [SVProgressHUD showErrorWithStatus:error.localizedDescription];
               //endrefresh操作
               [self endTableViewHeaderRefreshing];

           });
       }];
}
#pragma mark - private method

-(void)endTableViewHeaderRefreshing{
    
    UIViewController *controller = [self getCurrentVC];
    
    //当前控制器是导航控制器
    if ([[self getCurrentVC]isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *navi = (UINavigationController *)[self getCurrentVC];
        
        controller = [navi viewControllers][0];
    }
 
    [self traverseAllSubviews:controller.view];
    
}

-(void)traverseAllSubviews:(UIView *)rootView {
    for (UIView *subView in [rootView subviews])
    {
        if (!rootView.subviews.count) {
            return;
        }
        
        //如果是tableview 取消刷新
        if ([subView isKindOfClass:[UITableView class]]) {
            __weak UITableView *tableview = (UITableView *)subView;
            [tableview.mj_header endRefreshing];
        }
        [self traverseAllSubviews:subView];
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

@end
