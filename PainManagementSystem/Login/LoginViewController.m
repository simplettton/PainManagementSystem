//
//  LoginViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/22.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "BaseHeader.h"
#import "SetNetWorkView.h"
#import <SVProgressHUD.h>

#import "NetWorkTool.h"
#import "Pack.h"
#import "Unpack.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>

#import <GCDAsyncUdpSocket.h>

#define UdpSendPort 32345
#define UdpReceivePort 22345

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIView *userView;
@property (weak, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *remenberNameSwitch;

@end

@implementation LoginViewController
{
    GCDAsyncUdpSocket *udpSocket;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //编辑框下横线
    [self setBorderWithView:self.userView top:NO left:NO bottom:YES right:NO borderColor:UIColorFromHex(0Xbbbbbb) borderWidth:1.0];
    [self setBorderWithView:self.passwordView top:NO left:NO bottom:YES right:NO borderColor:UIColorFromHex(0XBBBBBB) borderWidth:1.0];
    
    //初始化udp soket
    [self setupSocket];

    //用户名显示
    NSString *userName = [UserDefault objectForKey:@"UserName"];
    
    BOOL hasRememberUserName = [UserDefault boolForKey:@"HasRememberName"];
    
    self.userNameTextField.text = hasRememberUserName ? userName : @"";
    
    [self.passwordTextField setSecureTextEntry:YES];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
}
//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self hideKeyBoard];
}
-(void)hideKeyBoard{
    [self.view endEditing:YES];
    
}
- (IBAction)login:(id)sender {
    [self loginCheck];
}

-(void)showLoginingIndicator{

    [SVProgressHUD showWithStatus:@"正在登录中..."];
}

-(void)loginCheck{
    
    //是否记住与用户名
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self.remenberNameSwitch isOn]) {
        [defaults setBool:YES forKey:@"HasRememberName"];
    }else{
        [defaults setBool:NO forKey:@"HasRememberName"];
    }
    [defaults synchronize];
    
    //UIStorybord 跳转
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    __block UINavigationController *controller ;
    
    //异步请求真的数据
    NSString *userName = self.userNameTextField.text;
    NSString *pwd = self.passwordTextField.text;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/User/Login"]
    params:@{
             @"username":userName,
             @"pwd":pwd
             }
    hasToken:NO
    success:^(HttpResponse *responseObject) {
        NSString *resutlt = responseObject.result;
        if ([resutlt intValue] == 1) {
            
            [self showLoginingIndicator];
            NSDictionary *content = responseObject.content;
            NSLog(@"receive content = %@",content);
            
            NSString *token = [responseObject.content objectForKey:@"token"];
            
            NSString *role = [responseObject.content objectForKey:@"role"];
            
            
            if ([role isEqualToString:@"_nurse"]) {
                
                controller =  [mainStoryBoard instantiateViewControllerWithIdentifier:@"NurseTabBarController"];
            }else if([role isEqualToString:@"_pmadmin"]){
                controller =  [mainStoryBoard instantiateViewControllerWithIdentifier:@"AgentNavigation"];
            }else{
                [SVProgressHUD showErrorWithStatus:@"该账号权限无法登陆系统"];
            }

            
            if(controller !=nil){
                //登录成功保存token role
                NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
                
                [userDefault setObject:token forKey:@"Token"];
                
                [userDefault setObject:role forKey:@"Role"];
                
                [userDefault setBool:YES forKey:@"IsLogined"];
                
                [userDefault synchronize];
                
                [self performSelector:@selector(initRootViewController:) withObject:controller afterDelay:0.25];
            }

            
        }else{
            NSString *error = responseObject.errorString;
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:error];
            });
        }
    
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];

    });
    if (controller) {
        [self performSelector:@selector(initRootViewController:) withObject:controller afterDelay:0.25];
    }

}

-(void)initRootViewController:(UIViewController *)controller{
    
    //登录成功后保存账户信息
    [self saveUserInfo];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *myDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        myDelegate.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
        [myDelegate.window.rootViewController removeFromParentViewController];
        [UIView transitionWithView:myDelegate.window
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            myDelegate.window.rootViewController = controller;
                        }
                        completion:nil];
        [myDelegate.window makeKeyAndVisible];
        [SVProgressHUD dismiss];
    });
}

-(void)saveUserInfo{
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/User/SelfInfo"]
                                  params:@{ }
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {
                                         NSDictionary *content = responseObject.content;
                                         
                                         NSLog(@"%@",content);
                                         
                                         [UserDefault setObject:content[@"hospital"] forKey:@"Hospital"];
                                         [UserDefault setObject:content[@"username"] forKey:@"UserName"];
                                         [UserDefault setObject:content[@"personname"] forKey:@"PersonName"];
                                         [UserDefault setObject:content[@"department"] forKey:@"Department"];
                                         if (content[@"contact"]!=[NSNull null]) {
                                             [UserDefault setObject:content[@"contact"] forKey:@"Contact"];
                                         }
 
                                         if (content[@"note"] != [NSNull null]) {
                                             [UserDefault  setObject:content[@"note"] forKey:@"Note"];
                                         }
                                         
                                         [UserDefault synchronize];
                                     }else{
                                         NSLog(@"error = %@",responseObject.errorString);
                                     }
                                 }
                                 failure:nil];
    
}

- (IBAction)setNetwork:(id)sender {
    [SetNetWorkView alertControllerAboveIn:self return:^(NSString *ipString) {
        [UserDefault setObject:ipString forKey:@"HTTPServerURLString"];
        [UserDefault synchronize];
    }];
}

#pragma mark - udpSocket

- (void)setupSocket
{
    
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    [udpSocket enableBroadcast:YES error:&error];
    
    if (![udpSocket bindToPort:UdpReceivePort error:&error])
    {
        NSLog(@"error :%@",error);
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return;
    }
    
    [self send:[Pack packetWithCmdid:0xff dataEnabled:NO data:nil]];
    
}
     
- (void)send:(NSData *)data
{
    NSDictionary *localWifiDic = [self getLocalInfoForCurrentWiFi];
    
    //获取当前wifi广播地址
    NSString *broadCast = [localWifiDic objectForKey:@"broadcast"];
    
    [udpSocket sendData:data toHost:broadCast port:UdpSendPort withTimeout:-1 tag:1];

}
#pragma mark - udp socket delegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"did send");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    
    NSData *receiveData = [Unpack unpackData:data];
    
    if (receiveData)
    {
        Byte *data = (Byte *)[receiveData bytes];
        
        Byte portByte[] = {data[5],data[6]};
        
        UInt16 PORT = [self lBytesToInt: portByte withLength:2];
        
        NSString *serverIp = [NSString stringWithFormat:@"http://%d.%d.%d.%d:%d/",data[1],data[2],data[3],data[4],PORT];
        
        NSLog(@"serverIp = %@",serverIp);
        
        [UserDefault setObject:serverIp forKey:@"HTTPServerURLString"];
        
        [UserDefault synchronize];
        
    }
    else
    {
        NSString *host = nil;
        uint16_t port = 22345;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        NSLog(@"RECV: Unknown message from: %@:%hu", host, port);
    }
}

#pragma mark - private method

- (NSMutableDictionary *)getLocalInfoForCurrentWiFi {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        //*/
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    //----192.168.1.255 广播地址
                    NSString *broadcast = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                    if (broadcast) {
                        [dict setObject:broadcast forKey:@"broadcast"];
                    }

                    //--192.168.1.106 本机地址
                    NSString *localIp = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    if (localIp) {
                        [dict setObject:localIp forKey:@"localIp"];
                    }

                    //--255.255.255.0 子网掩码地址
                    NSString *netmask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                    if (netmask) {
                        [dict setObject:netmask forKey:@"netmask"];
                    }

                    //--en0 端口地址
                    NSString *interface = [NSString stringWithUTF8String:temp_addr->ifa_name];
                    if (interface) {
                        [dict setObject:interface forKey:@"interface"];
                    }

                    return dict;
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    return dict;
}



- (void)setBorderWithView:(UIView *)view top:(BOOL)top left:(BOOL)left bottom:(BOOL)bottom right:(BOOL)right borderColor:(UIColor *)color borderWidth:(CGFloat)width
{
    if (top) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (left) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (bottom) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, view.frame.size.height - width, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (right) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(view.frame.size.width - width, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
}

//Byte数组转成int类型
-(int) lBytesToInt:(Byte[]) byte withLength:(int)length
{
    int height = 0;
    NSData * testData =[NSData dataWithBytes:byte length:length];
    for (int i = 0; i < [testData length]; i++)
    {
        if (byte[[testData length]-i] >= 0)
        {
            height = height + byte[[testData length]-i];
        } else
        {
            height = height + 256 + byte[[testData length]-i];
        }
        height = height * 256;
    }
    if (byte[0] >= 0)
    {
        height = height + byte[0];
    } else {
        height = height + 256 + byte[0];
    }
    return height;
}
@end
