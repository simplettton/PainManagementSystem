//
//  DeviceDetailController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceDetailController.h"
#import "TimeLineModel.h"
#import "BETimeLine.h"

@interface DeviceDetailController ()
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
@property (weak, nonatomic) IBOutlet UIView *alertContentView;

@property (strong,nonatomic)BETimeLine *timeLine;
@end

@implementation DeviceDetailController{
    NSMutableArray *datas;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if (self.machine) {
        [self getAlertInfomation];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.machine) {
        [self configureUIWithDataModel:self.machine];
    }else{
        if (self.medicalNum) {
            [self getInformFromNetworkWithMedicalNum:self.medicalNum];
        }
    }

}
-(void)getInformFromNetworkWithMedicalNum:(NSString *)medicalNum{
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/QueryTask"] params:@{
                                                                                                                          @"medicalrecordnum":medicalNum,
                                                                                                                          @"needlocal":@1,
                                                                                                                          @"taskstate":@135
                                                                                                                          }
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result integerValue] == 1) {
                                         NSArray *content = responseObject.content;
                                         if (content) {
                                             MachineModel *machine = [MachineModel modelWithDic:content[0]];
                                             [self configureUIWithDataModel:machine];
                                         }
                                     }
                                 }
                                 failure:nil];
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
    if (self.medicalNum) {
        self.isFocusLabel.text = @"已关注";
        self.leftTimeLabel.text = @"----";
    }else{
        if (machine.isFocus) {
            self.isFocusLabel.text = @"已关注";
        }else{
            self.isFocusLabel.text = @"未关注";
        }
        if (machine.leftTimeNumber) {
            self.leftTimeLabel.text = [self changeSecondToTimeString:machine.leftTimeNumber];
        }else{
            self.leftTimeLabel.text = @"----";
        }
    }
}
-(NSString *)changeSecondToTimeString:(NSNumber *)second{
    NSString *min = [NSString stringWithFormat:@"%ldmin",[second integerValue]/60];
    return min;
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
                                                 TimeLineModel *model = [TimeLineModel modelWithDic:dic];
                                                 BOOL containSameModel = NO;
                                                 for (TimeLineModel *timeLineModel in datas) {
                                                     if ([timeLineModel.timeStamp integerValue] == [model.timeStamp integerValue]) {
                                                         containSameModel = YES;
                                                         break;
                                                     }
                                                 }
                                                 if (!containSameModel) {
                                                     [datas addObject:model];
                                                 }
                                             }
                                             self.automaticallyAdjustsScrollViewInsets = YES;
                                             self.timeLine = [[BETimeLine alloc]init];
                                             [self.timeLine setSuperView:self.alertContentView DataArray:datas];
                                             

                                             
                                         }else{
                                             self.alertView.hidden = YES;
                                         }
                                     }
                                 }
                                 failure:nil];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 3;
}
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}
@end
