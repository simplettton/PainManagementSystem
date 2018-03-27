//
//  AddPatientViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddPatientViewController.h"
#import "NSDate+BRAdd.h"
#import "BETextField.h"
#import <BRPickerView.h>
#import "BaseHeader.h"
@interface AddPatientViewController ()
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *editViews;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControll;
@property (weak, nonatomic) IBOutlet UITextField *medicalRecordNumTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextFiled;

@property (weak, nonatomic) IBOutlet BETextField *birthdayTF;
@property (weak, nonatomic) IBOutlet UILabel *treatDateLabel;
@property (weak, nonatomic) IBOutlet UIView *birthDayView;
@property (weak, nonatomic) IBOutlet UIView *treatDayView;

@end

@implementation AddPatientViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self initAll];
}

-(void)initAll{
    if (self.dataDic == nil) {
        self.title = @"增加病历";
        //当前时间戳
        NSString *ts = [NSString stringWithFormat:@"%ld", time(NULL)];
        self.treatDateLabel.text = [self stringFromTimeIntervalString:ts dateFormat:@"yyyy-MM-dd"];
        self.birthdayTF.text = [self stringFromTimeIntervalString:ts dateFormat:@"yyyy-MM-dd"];
    }else{
        self.title = @"修改病历";
        self.medicalRecordNumTextField.text = [self.dataDic objectForKey:@"medicalRecordNum"];
        self.nameTextField.text = [self.dataDic objectForKey:@"name"];
        self.phoneTextFiled.text = [self.dataDic objectForKey:@"phone"];
        
        NSString *gender = [self.dataDic objectForKey:@"gender"];
        NSArray *genderArray = @[@"男",@"女",@"其他"];
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
