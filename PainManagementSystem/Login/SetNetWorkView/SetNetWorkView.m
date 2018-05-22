//
//  SetNetWorkView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/22.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//
#define KVIEW_H [UIScreen mainScreen].bounds.size.height
#define KVIEW_W [UIScreen mainScreen].bounds.size.width

#import "SetNetWorkView.h"
#import "BaseHeader.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <GCDAsyncUdpSocket.h>
#import "Pack.h"
#import "Unpack.h"

#define UdpSendPort 32345
#define UdpReceivePort 22345

@interface SetNetWorkView()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *setButton;
@property (weak, nonatomic) IBOutlet UITextField *IPTextFileld;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *titleView;
@property(nonatomic,strong)NSTimer *timer;
//port
@property (weak, nonatomic) IBOutlet UITextField *serverPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *mqttPortTextField;

@end
@implementation SetNetWorkView
{
    GCDAsyncUdpSocket *udpSocket;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    self.backgroundView.layer.cornerRadius = 5;
    self.titleView.layer.cornerRadius = 5;
    self.IPTextFileld.delegate = self;
    
    //下横线
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, self.contentView.frame.size.height - 1.0, _contentView.frame.size.width, 0.5);
    layer.backgroundColor = UIColorFromHex(0XBBBBBB).CGColor;
    [self.contentView.layer addSublayer:layer];
    
}
+(void)alertControllerAboveIn:(UIViewController *)controller return:(returnIP)returnEvent{
    
    SetNetWorkView *view = [[NSBundle mainBundle]loadNibNamed:@"SetNetWorkView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KVIEW_W, KVIEW_H);
    
    view.returnEvent = returnEvent;
    
    [view configureUI];

    [controller.view addSubview:view];
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    
    view.backgroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.2,0.2);
    view.backgroundView.alpha = 0;
    
    [UIView animateWithDuration:0.3 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
        view.backgroundView.transform = transform;
        view.backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
}
- (IBAction)cancel:(id)sender {
    if (self.timer) {
        [self closeTimer];
    }
    [self removeFromSuperview];
}
- (IBAction)setIP:(id)sender {
    if (![self checkIpAdress:self.IPTextFileld.text]) {
        [SVProgressHUD showErrorWithStatus:@"请输入有效ip地址"];
    }else{
        NSString *IPString = self.IPTextFileld.text;
        NSString *serverPort = self.serverPortTextField.text;
        NSString *MQTTPort = self.mqttPortTextField.text;
        
        [UserDefault setObject:IPString forKey:@"HTTPServerIP"];
        [UserDefault setObject:serverPort forKey:@"HTTPServerPort"];
        [UserDefault setObject:MQTTPort forKey:@"MQTTPort"];

        NSString *ip = [NSString stringWithFormat:@"http://%@:%@/",IPString,serverPort];
        [UserDefault setObject:ip forKey:@"HTTPServerURLSting"];
        [UserDefault synchronize];
        
        self.returnEvent(ip);
        [self removeFromSuperview];
    }
    if (self.timer) {
        [self closeTimer];
    }
}

-(void)configureUI{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *IPString = [defaults objectForKey:@"HTTPServerIP"];
    NSString *serverPort = [defaults objectForKey:@"HTTPServerPort"];
    NSString *MQTTPort  = [defaults objectForKey:@"MQTTPort"];
    

    
    self.IPTextFileld.text = IPString;
    self.serverPortTextField.text = serverPort;
    self.mqttPortTextField.text = MQTTPort;

}
- (IBAction)getIp:(id)sender {
    
    //初始化udp soket
    [self setupSocket];
    [self startTimer];
    [SVProgressHUD showWithStatus:@"正在自动获取ip地址..."];
}

//ip地址规范
-(BOOL)checkIpAdress:(NSString *)inputString{
    if (inputString.length == 0) return NO;
    NSString *regex = @"([1-9]|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pred evaluateWithObject:inputString];
}
#pragma mark - udpSocket

- (void)setupSocket
{
    if (udpSocket == nil) {
        
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        NSError *error = nil;
        
        [udpSocket enableBroadcast:YES error:&error];
        
        if (![udpSocket bindToPort:UdpReceivePort error:&error])
        {
            NSLog(@"error :%@",error);
            //        return;
        }
        if (![udpSocket beginReceiving:&error])
        {
            NSLog(@"Error receiving: %@", error);
            //        return;
        }
    }

    [self refreshIpAddress];
    
}
-(void)refreshIpAddress{
    
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
    [self closeTimer];
    [SVProgressHUD showSuccessWithStatus:@"已获取服务器ip地址"];
    NSData *receiveData = [Unpack unpackData:data];
    
    if (receiveData)
    {
        Byte *data = (Byte *)[receiveData bytes];
        
        Byte portByte[] = {data[5],data[6]};
        
        UInt16 PORT = [self lBytesToInt: portByte withLength:2];
        
        Byte MQTTPortByte[] = {data[7],data[8]};
        
        UInt16 MQTTPort = [self lBytesToInt:MQTTPortByte withLength:2];
        
        NSString *serverIp = [NSString stringWithFormat:@"http://%d.%d.%d.%d:%d/",data[1],data[2],data[3],data[4],PORT];
        
        NSLog(@"serverIp = %@",serverIp);
        
        self.IPTextFileld.text = [NSString stringWithFormat:@"%d.%d.%d.%d",data[1],data[2],data[3],data[4]];
        self.serverPortTextField.text = [NSString stringWithFormat:@"%d",PORT];
        self.mqttPortTextField.text = [NSString stringWithFormat:@"%d",MQTTPort];

        
    }
    else
    {
        NSString *host = nil;
        uint16_t port = 22345;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        
        NSLog(@"RECV: Unknown message from: %@:%hu", host, port);
    }
}
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
#pragma mark - timer
-(void)startTimer{
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(showFailHUD) userInfo:nil repeats:NO];
}
-(void)showFailHUD{
    [SVProgressHUD showErrorWithStatus:@"无法获取地址"];
}
-(void)closeTimer{
    // 停止定时器
    [self.timer invalidate];
    self.timer = nil;
}
-(void)dealloc{
   
    if (udpSocket) {
        [udpSocket close];
    }

}
#pragma mark - textField delegate
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSCharacterSet *cs;
    cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."]invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs]componentsJoinedByString:@""];
    BOOL hasCharacter = [string isEqualToString:filtered];
    if (!hasCharacter) {
        return NO;
    }
    return YES;
}
@end
