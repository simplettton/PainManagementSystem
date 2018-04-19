                                                                                 //
//  AddPatientViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddPatientViewController.h"
#import "QRCodeReaderViewController.h"
#import "NSDate+BRAdd.h"
#import "BETextField.h"
#import <BRPickerView.h>
#import "BaseHeader.h"
@interface AddPatientViewController ()<QRCodeReaderDelegate>
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *editViews;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *requiredTextFields;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControll;
@property (weak, nonatomic) IBOutlet UITextField *medicalRecordNumTextField;

@property (weak, nonatomic) IBOutlet UITextField *bedNumTextField;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextFiled;

@property (weak, nonatomic) IBOutlet BETextField *birthdayTF;
@property (weak, nonatomic) IBOutlet UILabel *treatDateLabel;
@property (weak, nonatomic) IBOutlet UIView *birthDayView;
@property (weak, nonatomic) IBOutlet UIView *treatDayView;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;


@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *nameLabels;

//条形码扫描
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@end

@implementation AddPatientViewController{
    NSArray *genderArray;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self initAll];
}

-(void)initAll{
   
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(save:)];
    
    genderArray = @[@"男",@"女",@"其他"];

    for (UILabel *label in self.nameLabels) {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:label.text];

        [string addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(0xFD8574) range:NSMakeRange([label.text length]-1,1)];

        label.attributedText = string;
    }
    if (self.patient == nil) {
        self.title = @"增加病历";
        self.scanButton.hidden = NO;
        //当前时间戳
        NSString *ts = [NSString stringWithFormat:@"%ld", time(NULL)];

        self.treatDateLabel.text = [self stringFromTimeIntervalString:ts dateFormat:@"yyyy-MM-dd"];

        
        self.birthdayTF.text = [self stringFromTimeIntervalString:ts dateFormat:@"yyyy-MM-dd"];
        
    }else{
        self.title = @"修改病历";
        self.scanButton.hidden = YES;
        
        //病历不可修改
        self.medicalRecordNumTextField.text = self.patient.medicalRecordNum;
        self.medicalRecordNumTextField.enabled = NO;
        
        self.nameTextField.text = self.patient.name;
        self.phoneTextFiled.text = self.patient.contact;
        
        self.treatDateLabel.text = [self stringFromTimeIntervalString:self.patient.registeredTimeString dateFormat:@"yyyy-MM-dd"];
        
        
        self.birthdayTF.text = [self stringFromTimeIntervalString:self.patient.birthdayString dateFormat:@"yyyy-MM-dd"];
        
        self.bedNumTextField.text = self.patient.bednum;
        
        NSString *gender = self.patient.gender;
        NSInteger selectedIndex = [genderArray indexOfObject:gender];
        [self.segmentedControll setSelectedSegmentIndex:selectedIndex];
        
    }
    for (UIView *view in self.editViews) {
        view.layer.borderWidth = 0.5f;
        view.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
    }
    
    CGRect frame=  self.segmentedControll.frame;
    CGFloat fNewHeight = 35.0f;
    [self.segmentedControll setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, fNewHeight)];
    
    
    __weak typeof(self) weakSelf = self;
    [self.birthdayTF addTapAciton:^{

        [BRDatePickerView showDatePickerWithTitle:@"出生日期"
                                         dateType:UIDatePickerModeDate
                                  defaultSelValue:weakSelf.birthdayTF.text
                                       minDateStr:nil
                                       maxDateStr:[NSDate currentDateString]
                                     isAutoSelect:NO
                                       themeColor:nil
                                      resultBlock:^(NSString *selectValue) {
                                            weakSelf.birthdayTF.text = selectValue;
                                            NSString *timeStamp = [self timeStampFromTimeString:selectValue dataFormat:@"yyyy-MM-dd"];

                                            NSLog(@"------send to server ：生日时间戳：%@",timeStamp);
        } cancelBlock:^{
        }];

    }];
    
}
- (IBAction)save:(id)sender {
    
    for (UITextField *textField in self.requiredTextFields) {
        if ([textField.text length] == 0) {
            [SVProgressHUD setErrorImage:[UIImage imageNamed:@""]];
            [SVProgressHUD setMaximumDismissTimeInterval:0.5];
            [SVProgressHUD showErrorWithStatus:@"参数不能为空"];
        }
    }
    
    NSString *api;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:20];
    if (self.patient == nil) {
        api = @"Api/Patient/Add";
    }else{
        api = @"Api/Patient/ChangeInfo";
    }
    //参数
    NSString *gender = genderArray[self.segmentedControll.selectedSegmentIndex];
    
    NSString *birthdayString = [self timeStampFromTimeString:self.birthdayTF.text dataFormat:@"yyyy-MM-dd"];
    
    [params setObject:self.medicalRecordNumTextField.text forKey:@"medicalrecordnum"];
    
    [params setObject:self.nameTextField.text forKey:@"name"];
    
    [params setObject:gender forKey:@"gender"];
    
    [params setObject:birthdayString forKey:@"birthday"];
    
    [params setObject:self.phoneTextFiled.text forKey:@"contact"];
    
    if ([self.bedNumTextField.text length]>0) {
        
        [params setObject:self.bedNumTextField.text forKey:@"bednum"];
    }


    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:api]
                                  params:params
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                     if ([responseObject.result intValue]==1) {
                                         [SVProgressHUD setSuccessImage:[UIImage imageNamed:@""]];

                                         [SVProgressHUD showSuccessWithStatus:@"保存成功"];
                                         
                                         [self.navigationController popViewControllerAnimated:YES];

                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];

                                     }


                                  } failure:nil];
    
}
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
    _reader.delegate = self;
    
    
    [self presentViewController:_reader animated:YES completion:NULL];
}
#pragma mark - QRCodeReader Delegate Methods
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        self.medicalRecordNumTextField.text = result;
        NSLog(@"QRretult == %@", result);
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - private method

//时间戳字符串转化为日期或时间
- (NSString *)stringFromTimeIntervalString:(NSString *)timeString dateFormat:(NSString*)dateFormat
{
    // 格式化时间
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone: [NSTimeZone timeZoneWithName:@"Asia/Beijing"]];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:dateFormat];
    
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]];
    NSString* dateString = [formatter stringFromDate:date];
    
    return dateString;
}

//日期字符转为时间戳
-(NSString *)timeStampFromTimeString:(NSString *)timeString dataFormat:(NSString *)dateFormat
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"shanghai"];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:dateFormat];
    
    //日期转时间戳
    NSDate *date = [formatter dateFromString:timeString];
    NSInteger timeSp = [[NSNumber numberWithDouble:[date timeIntervalSince1970]] integerValue];
    NSString* timeStamp = [NSString stringWithFormat:@"%ld",timeSp];
    return timeStamp;
    
    
}

@end
