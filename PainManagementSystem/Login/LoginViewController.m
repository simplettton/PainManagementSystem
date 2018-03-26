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

#import "NetWorkTool.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>

#import <GCDAsyncUdpSocket.h>
#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIView *userView;
@property (weak, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *remenberNameSwitch;

@end

@implementation LoginViewController{
    GCDAsyncUdpSocket *udpSocket;
        NSMutableString *log;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setBorderWithView:self.userView top:NO left:NO bottom:YES right:NO borderColor:UIColorFromHex(0Xbbbbbb) borderWidth:1.0];
    [self setBorderWithView:self.passwordView top:NO left:NO bottom:YES right:NO borderColor:UIColorFromHex(0XBBBBBB) borderWidth:1.0];
    
    log = [[NSMutableString alloc] init];
    [self setupSocket];
    
    

    for (int i =255 ; i<256; i++) {

        [self send:i];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [defaults objectForKey:@"UserName"];
    self.userNameTextField.text = (userName==nil) ? @"" : userName;
    
//    self.IPTextFileld.text = IPString == nil? @"http://192.128.127" :IPString;

}
- (IBAction)login:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self.remenberNameSwitch isOn]) {
        [defaults setObject:self.userNameTextField.text forKey:@"UserName"];
    }else{
        [defaults setObject:nil forKey:@"UserName"];
    }
        [defaults synchronize];
    
    //UIStorybord 跳转
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *controller ;
    
    if ([self.userNameTextField.text isEqualToString: @"agent"]) {

        controller = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AgentNavigation"];
        
    }else if([self.userNameTextField.text isEqualToString:@"nurse"]){
        
        controller =     [mainStoryBoard instantiateViewControllerWithIdentifier:@"NurseTabBarController"];
    }
    NetWorkTool *netWorkTool = [NetWorkTool sharedNetWorkTool];
    NSString * address = [HTTPServerURLSting stringByAppendingString:@"Api/User/Login"];
    NSDictionary *parameter = @{
                                @"token":@"",
                                @"data":
                                        @{
                                            @"username":@"zengbinger",
                                            @"pwd":@"123456"
                                        }
                                };
    

    [netWorkTool POST:address
           parameters:parameter
             progress:nil
              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                  NSDictionary *jsonDict = responseObject;
                  if (jsonDict != nil) {
//                      NSString *state = [jsonDict objectForKey:@"result"];
//                      if ([state intValue] == 1) {
//                          NSArray *dataDic = [jsonDict objectForKey:@"body"];
//                          
//                          for(NSDictionary *dic in dataDic){
//
//                          }
//                          dispatch_async(dispatch_get_main_queue(), ^{
//                              
//                              [self.tableView reloadData];
//                              self.accumulateTimeLabel.text = [NSString stringWithFormat:@"%ld",(long)accumulateTime];
//                          });
//                      }
                  }
                  
                  NSLog(@"receive  %@",responseObject);
              } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                  NSLog(@"error==%@",error);
              }];
    
    AppDelegate *myDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    myDelegate.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    //        [myDelegate.window setRootViewController:myDelegate.drawerController];

    [UIView transitionWithView:myDelegate.window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        myDelegate.window.rootViewController = controller;
                    }
                    completion:nil];
    [myDelegate.window makeKeyAndVisible];
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
- (IBAction)setNetwork:(id)sender {
    [SetNetWorkView alertControllerAboveIn:self return:^(NSString *ipString) {
        NSLog(@"IPString = %@",ipString);
    }];
}
//
//- (NSString *)localIPAddress
//{
//    NSString *localIP = nil;
//    struct ifaddrs *addrs;
//    if (getifaddrs(&addrs)==0) {
//        const struct ifaddrs *cursor = addrs;
//        while (cursor != NULL) {
//            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
//            {
//                //NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
//                //if ([name isEqualToString:@"en0"]) // Wi-Fi adapter
//                {
//                    localIP = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
//                    break;
//                }
//            }
//            cursor = cursor->ifa_next;
//        }
//        freeifaddrs(addrs);
//    }
//    return localIP;
//
//}
#pragma mark - udpSocket

- (void)setupSocket
{
    
    
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if (![udpSocket bindToPort:12345 error:&error])
    {
        [self logError:FORMAT(@"Error binding: %@", error)];
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        [self logError:FORMAT(@"Error receiving: %@", error)];
        return;
    }
    
    [self logInfo:@"Ready"];
}
- (void)logError:(NSString *)msg
{
    NSString *prefix = @"<font color=\"#B40404\">";
    NSString *suffix = @"</font><br/>";
    
    [log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
    
    NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
    //    [webView loadHTMLString:html baseURL:nil];
}

- (void)logInfo:(NSString *)msg
{
    NSString *prefix = @"<font color=\"#6A0888\">";
    NSString *suffix = @"</font><br/>";
    
    [log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
    
    NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
    //    [webView loadHTMLString:html baseURL:nil];
}

- (void)logMessage:(NSString *)msg
{
    NSString *prefix = @"<font color=\"#000000\">";
    NSString *suffix = @"</font><br/>";
    
    [log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
    
    NSString *html = [NSString stringWithFormat:@"<html><body>%@</body></html>", log];
    //    [webView loadHTMLString:html baseURL:nil];
}
     
- (IBAction)send:(NSInteger)number
{

    NSString *host = [NSString stringWithFormat:@"192.168.255.%ld",(long)number];
    
//    int port = [portField.text intValue];

    NSString *msg = [NSString stringWithFormat:@"tttttttttest"];

    
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [udpSocket sendData:data toHost:host port:12345 withTimeout:-1 tag:1];

}
#pragma mark - delegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"did send");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        [self logMessage:FORMAT(@"RECV: %@", msg)];
    }
    else
    {
        NSString *host = nil;
        uint16_t port = 22345;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        [self logInfo:FORMAT(@"RECV: Unknown message from: %@:%hu", host, port)];
    }
}

@end
