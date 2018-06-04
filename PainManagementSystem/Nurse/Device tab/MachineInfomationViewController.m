//
//  MachineInfomationViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "MachineInfomationViewController.h"

@interface MachineInfomationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *medicalNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *bedNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serialNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *isFocusLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *alertView;

@end

@implementation MachineInfomationViewController{
    NSMutableArray *datas;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self getAlertInfomation];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureUIWithDataModel:self.machine];
}

-(void)configureUIWithDataModel:(MachineModel *)machine{
    //patient
    self.medicalNumLabel.text = [NSString stringWithFormat:@"病历号： %@",machine.userMedicalNum];
    self.patientNameLabel.text = [NSString stringWithFormat:@"病人姓名： %@",machine.userName];
    if ([machine.userBedNum isEqualToString:@""]) {
        self.bedNumLabel.text = @"";
    }else{
        self.bedNumLabel.text = [NSString stringWithFormat:@"病床号： %@",machine.userBedNum];
    }
    self.ageLabel.text = [NSString stringWithFormat:@"年龄： %@",machine.userAge];
    self.contactLabel.text = [NSString stringWithFormat:@"电话： %@",machine.userContact];
    //machine
    self.taskStateLabel.text = machine.taskStateString;
    self.nameLabel.text = machine.name;
    self.typeLabel.text = machine.type;
    self.serialNumLabel.text = machine.serialNum;
    self.machineStateLabel.text = machine.state;
    self.timeLabel.text = machine.treatTime;
    if (machine.isFocus) {
        self.isFocusLabel.text = @"已关注";
    }else{
        self.isFocusLabel.text = @"未关注";
    }
}
-(void)getAlertInfomation{
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/DeviceWarning/ListByRecore"]
                                  params:@{@"recoreid":self.machine.taskId}
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result integerValue] == 1) {
                                         NSArray *content = responseObject.content;
                                         if ([content count]>0) {
                                             self.alertView.hidden = NO;
                                             for (NSDictionary *dic in content) {
                                                 [datas addObject:dic];
                                             }
                                         }else{
                                             self.alertView.hidden = YES;
                                         }
                                     }
                                 }
                                 failure:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
