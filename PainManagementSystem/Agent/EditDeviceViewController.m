//
//  EditDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/20.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditDeviceViewController.h"
#import "LoginViewController.h"
//#import "BaseHeader.h"
#import "QRCodeReaderViewController.h"
@interface EditDeviceViewController ()<QRCodeReaderDelegate>
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *serialNumTextField;
@property (weak, nonatomic) IBOutlet UILabel *macLabel;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;

//条形码扫描
@property (strong,nonatomic) QRCodeReaderViewController *reader;

@end

@implementation EditDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设备管理系统";
    self.navigationItem.hidesBackButton = YES;
    [self initAll];
}
//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self hideKeyBoard];
}
-(void)hideKeyBoard{
    [self.view endEditing:YES];
    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange) name:UITextFieldTextDidChangeNotification object:nil];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}
-(void)textFieldDidChange{
    //限制20位
    if (self.nameTextField.text.length > 20) {
        self.nameTextField.text = [self.nameTextField.text substringToIndex:20];
    }
}

-(void)initAll{
    self.macLabel.text = self.macString;

    self.typeLabel.text = self.type;

    self.nameTextField.text = self.name;

    self.serialNumTextField.text = self.serialNum;
    
    for (UITextField *textField in self.textFields) {
        textField.layer.borderWidth = 1.0f;
        textField.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
        textField.leftView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 51)];
        textField.leftViewMode=UITextFieldViewModeAlways;
    }
}
- (IBAction)submit:(id)sender {
    
    
    if ([self.nameTextField.text length] > 0 && [self.serialNumTextField.text length] > 0) {
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/DBDevice/Change"]
                                      params:@{
                                               @"cpuid":self.macString,
                                               @"nick":self.nameTextField.text,
                                               @"serialnum":self.serialNumTextField.text
                                               
                                               }
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {
                                         
                                         if ([responseObject.result intValue]==1) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                
                                                 [self performSegueWithIdentifier:@"BackToDeviceList" sender:nil];
                                             });
                                         }else{
                                             NSString *error = responseObject.errorString;
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [SVProgressHUD showErrorWithStatus:error];
                                             });
                                         }
                                     }
                                     failure:nil];
    }else{
        [SVProgressHUD showErrorWithStatus:@"提交的内容不能为空"];
    }
    
}

- (IBAction)logout:(id)sender {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:@"退出后不会删除任何历史数据，下次登录依然可以使用本账号。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    
    UIAlertAction* logoutAction = [UIAlertAction actionWithTitle:@"退出登录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        [UserDefault setBool:NO forKey:@"IsLogined"];
        
        [UserDefault synchronize];
        
        [[[UIApplication sharedApplication].delegate window].rootViewController removeFromParentViewController];
        
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        LoginViewController *vc = (LoginViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        
        [UIView transitionWithView:[[UIApplication sharedApplication].delegate window]
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.view.window.rootViewController = vc;
                        }
                        completion:nil];

        
        [[[UIApplication sharedApplication].delegate window] makeKeyAndVisible];
    }];
    
    [alert addAction:logoutAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - scan

- (IBAction)scan:(id)sender {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        
        
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"相机启用权限未开启"
                                                                       message:[NSString stringWithFormat:@"请在iPhone的“设置”-“隐私”-“相机”功能中，找到“%@”打开相机访问权限",[[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleDisplayName"]]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  
                                                                  NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                  [[UIApplication sharedApplication] openURL:url];
                                                                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Privacy&path=CAMERA"]];
                                                                  
                                                                  
                                                              }];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        
        return;
        
    }
    NSArray *types = @[
                       AVMetadataObjectTypeEAN13Code,
                       AVMetadataObjectTypeEAN8Code,
                       AVMetadataObjectTypeUPCECode,
                       AVMetadataObjectTypeCode39Code,
                       AVMetadataObjectTypeCode39Mod43Code,
                       AVMetadataObjectTypeCode93Code,
                       AVMetadataObjectTypeCode128Code,
                       AVMetadataObjectTypePDF417Code];
    
    _reader = [QRCodeReaderViewController readerWithMetadataObjectTypes:types];
    
    // Using delegate methods
    _reader.delegate = self;
    
    
    [self presentViewController:_reader animated:YES completion:NULL];
}


#pragma mark - QRCodeReader Delegate Methods
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (![self checkSerailNum:result]) {
            [SVProgressHUD showErrorWithStatus:@"请扫描有效序列号"];
        }else{
            self.serialNumTextField.text = result;
        }
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
//序列号正则
- (BOOL)checkSerailNum:(NSString *)inputString {
    if (inputString.length == 0) return NO;
    NSString *regex =@"^[A-Z]{1}[A-Z0-9]{3}\\d{2}[A-C1-9]{1}[A-Z0-9]{1}\\d{4}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pred evaluateWithObject:inputString];
}
@end
