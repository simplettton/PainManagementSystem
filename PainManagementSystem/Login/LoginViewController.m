//
//  LoginViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/22.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//


//ip限制
// "([1-9]|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3}";
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "BaseHeader.h"
#import "SetNetWorkView.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIView *userView;
@property (weak, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *remenberNameSwitch;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //编辑框下横线
    [self setBorderWithView:self.userView top:NO left:NO bottom:YES right:NO borderColor:UIColorFromHex(0Xbbbbbb) borderWidth:1.0];
    [self setBorderWithView:self.passwordView top:NO left:NO bottom:YES right:NO borderColor:UIColorFromHex(0XBBBBBB) borderWidth:1.0];


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
    
    if (self.userNameTextField.text.length == 0 || self.passwordTextField.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"用户名或密码不能为空"];
        return;
    }
    [self showLoginingIndicator];
    [self loginCheck];
}

-(void)showLoginingIndicator{

    [SVProgressHUD showWithStatus:@"正在登录中..."];
}

-(void)loginCheck{
    
    [self hideKeyBoard];
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
    
    } failure:nil];

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
    [self hideKeyBoard];
    [SetNetWorkView alertControllerAboveIn:self return:^(NSString *ipString) {
        [UserDefault setObject:ipString forKey:@"HTTPServerURLString"];
        [UserDefault synchronize];
    }];
}


#pragma mark - private method

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




@end
