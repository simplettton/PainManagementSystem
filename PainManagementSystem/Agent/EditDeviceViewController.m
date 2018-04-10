//
//  EditDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/20.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditDeviceViewController.h"

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
    [self initAll];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
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
    
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    
    [SVProgressHUD show];
    
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

#pragma mark - scan

- (IBAction)scan:(id)sender {
    NSArray *types = @[AVMetadataObjectTypeQRCode,
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
        self.serialNumTextField.text = result;
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
