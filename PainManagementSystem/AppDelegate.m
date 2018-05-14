//
//  AppDelegate.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/9.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate ()<UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIButton appearance] setExclusiveTouch:YES];
    [SVProgressHUD setMaximumDismissTimeInterval:1];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@""]];
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@""]];
    [SVProgressHUD setMinimumSize:CGSizeMake(100, 50)];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear]; //当HUD显示的时候，不允许用户交互，且显示背景图层自定义的颜色。
    [SVProgressHUD setBackgroundColor:UIColorFromHex(0xf9f9f9)];
    
    [SVProgressHUD setCornerRadius:5];
    
    if (![UserDefault objectForKey:@"HTTPServerURLString"]) {
        [UserDefault setObject:@"http://192.168.2.127:8888/" forKey:@"HTTPServerURLString"];
        [UserDefault synchronize];
    }
    
    [self registerAPN];
    
    //iOS 10 //请求通知权限, 本地和远程共用
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        //用户允许了push权限的申请
        if (granted) {
            NSLog(@"请求成功");
        } else {
            NSLog(@"请求失败");
        }
        
        if (!error) {
            
        }
    }];
    //注册远程通知
    [[UIApplication sharedApplication]registerForRemoteNotifications];
    
    //设置通知的代理
    center.delegate = self;
    //初始化
    [self initRootViewController];
    return YES;
}

-(void)initRootViewController{
    
     UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    __block UINavigationController *controller ;
    

//
    if ([self isUserLogin]) {
        
        NSString *role = [UserDefault objectForKey:@"Role"];
        if ([role isEqualToString:@"_nurse"]) {
            
            controller =  [mainStoryBoard instantiateViewControllerWithIdentifier:@"NurseTabBarController"];
        }else if([role isEqualToString:@"_pmadmin"]){
            controller =  [mainStoryBoard instantiateViewControllerWithIdentifier:@"AgentNavigation"];
        }

    }else{
        controller = [mainStoryBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    }
    
    //  初始化窗口、设置根控制器、显示窗口
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [UIView transitionWithView:self.window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.window.rootViewController = controller;
                    }
                    completion:nil];
    
    [self.window makeKeyAndVisible];
    
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -- 是否登录
-(BOOL)isUserLogin
{
    
    BOOL isLogined = [UserDefault boolForKey:@"IsLogined"];
    
    if (isLogined)
    {
        //已经登录
        return YES;
    }
    return NO;
}

-(void)registerAPN
{
    

    
    //
    //    //iOS 10 before
    //    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    //    [application registerUserNotificationSettings:settings];
    
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *tokenStr = [NSString stringWithFormat:@"%@",deviceToken];
     tokenStr = [tokenStr stringByReplacingOccurrencesOfString:@" " withString:@""];
     tokenStr = [tokenStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
     tokenStr = [tokenStr stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    //upload tokenStr to server
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    
}
@end
