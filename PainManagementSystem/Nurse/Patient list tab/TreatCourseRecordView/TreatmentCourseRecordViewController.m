//
//  TreatmentCourseRecordViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TreatmentCourseRecordViewController.h"
#import "VASMarkView.h"
#import "TreatRecordCell.h"
#import "RecordModel.h"
#import "RecordDetailViewController.h"

#import "MJRefresh.h"
@interface TreatmentCourseRecordViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientInfoLabel;

@end

@implementation TreatmentCourseRecordViewController{
    NSMutableArray *datas;
    NSString *markDescribe;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
    self.title = @"治疗疗程记录";
}

-(void)initAll{
    

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.tableHeaderView.hidden = YES;
    
    if (self.patient) {
        self.title = @"治疗疗程记录";
        [self updatePatientInfo];
    }
    self.nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.nameLabel.numberOfLines = 0;
    [self.nameLabel sizeToFit];
    
    self.patientInfoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.patientInfoLabel.numberOfLines = 0;
    [self.patientInfoLabel sizeToFit];

    datas = [[NSMutableArray alloc]initWithCapacity:20];

    [self initTableHeaderAndFooter];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self getStandardEvaluation];
}
#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
    //下拉刷新
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    // 隐藏时间
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    self.tableView.mj_header = header;
    [self.tableView.mj_header beginRefreshing];
}
-(void)refresh{
    NSString *paramValue = self.medicalRecordNum != nil? self.medicalRecordNum : self.patient.medicalRecordNum;
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TreatRecode/TreatRecodeList"]
                                  params:@{@"medicalrecordnum":paramValue}
                                hasToken:YES success:^(HttpResponse *responseObject) {
                                    [datas removeAllObjects];
                                    if ([responseObject.result intValue] == 1) {
                                        if (responseObject.content) {
                                            NSLog(@"dic = %@",responseObject.content);

                                            //从其他地方进入详情 刷新patientin信息
                                            if (self.medicalRecordNum) {
                                                self.patient = [PatientModel modelWithDic:responseObject.content[@"patient"]];
                                                [self updatePatientInfo];
                                            }
                                            
                                            NSArray *dataArray = responseObject.content[@"detail"];
                                            if (![dataArray isEqual:[NSNull null]]) {

                                                self.tableView.tableHeaderView.hidden = NO;
                                                for (NSDictionary *dic in dataArray) {
                                                    __block RecordModel *record = [RecordModel modelWithDic:dic];
                                                    record.patient = self.patient;
                                                    if(record.ID){
                                                        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TreatRecode/RecodeDetail"]
                                                                                      params:@{@"id":record.ID}
                                                                                    hasToken:YES
                                                                                     success:^(HttpResponse *responseObject) {
                                                                                         if ([responseObject.result integerValue]==1 ) {
                                                                                             NSDictionary *answerDic = responseObject.content;
                                                                                             NSLog(@"answer = %@",answerDic);
                                                                                             [record appendQuestionsWithDic:answerDic];
                                                                                             
                                                                                         }else{
                                                                                             
                                                                                         }
                                                                                     }
                                                                                     failure:nil];
                                                    }
                                                    
                                                    [datas addObject:record];
                                                }
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self.tableView reloadData];
                                                });
                                            }else{
                                                [SVProgressHUD showErrorWithStatus:@"当前没有记录~"];
                                                //没有数据隐藏表头
                                                self.tableView.tableHeaderView.hidden = YES;
                                            }
                                        }
                                    }else{
                                        [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                    }
                                } failure:nil];
}
-(void)updatePatientInfo{
    self.nameLabel.text = [NSString stringWithFormat:@"姓名:%@",self.patient.name];
    self.ageLabel.text = [NSString stringWithFormat:@"年龄:%@",self.patient.age];
    self.phoneLabel.text = [NSString stringWithFormat:@"电话:%@",self.patient.contact];
    self.patientInfoLabel.text = [NSString stringWithFormat:@"姓名:%@          年龄:%@          电话:%@",self.patient.name,self.patient.age,self.patient.contact];
}

#pragma mark - tableview delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    TreatRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TreatRecordCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    RecordModel *record = [datas objectAtIndex:indexPath.row];
    cell.treatTimeLB.text = record.timeString;
    cell.painfactorLB.text = record.painfactorW;
    cell.physicalTreatLB.text = record.machineType;
    cell.vasLabel.text = record.vasString;
    //不足三位前面补0
    cell.medicalRecodNumLB.text = [NSString stringWithFormat:@"%03zd",indexPath.row+1];
    
    [cell.markButton setTag:indexPath.row];
    [cell.markButton addTarget:self action:@selector(showVASMarkView:) forControlEvents:UIControlEventTouchUpInside];
    [cell.markButton setTag:indexPath.row];
    
    return cell;
}
-(void)showVASMarkView:(UIButton *)sender{
    
    UIView *contentView = [sender superview];
    TreatRecordCell *cell = (TreatRecordCell *)[contentView superview];
    RecordModel *record = [datas objectAtIndex:sender.tag];
    __block NSMutableArray *array = (NSMutableArray *)[cell.vasLabel.text componentsSeparatedByString:@"/"];
    __block NSString *idString = record.ID;
    __block NSNumber *isForceToStop;
//    if (self.medicalRecordNum || [record.machineType isEqualToString:@"血瘘"]) {
//        isForceToStop = @1;
//    }else{
//        isForceToStop = @0;
//    }
    
    if (self.isFocusToStop || [record.machineType isEqualToString:@"血瘘"]) {
        isForceToStop = @1;
    }else{
        isForceToStop = @0;
    }
    
    if (![[array objectAtIndex:1]isEqualToString:@"？"]) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:@"该治疗疗程记录已有VAS评分，是否再次修改评分？"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        
        [alert addAction:cancelAction];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [VASMarkView alertControllerAboveIn:self withData:@{
                                                                @"flag":isForceToStop,
                                                                @"id":idString,
                                                                @"mark":[array objectAtIndex:1]
                                                                }describe:markDescribe return:^(NSString *markString) {

                [array replaceObjectAtIndex:1 withObject:markString];
                
                NSString *newValue = [array componentsJoinedByString:@"/"];
                cell.vasLabel.text = newValue;
                if (self.medicalRecordNum) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
        }];
        
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        
    }else{

        [VASMarkView alertControllerAboveIn:self withData:@{
                                                            @"flag":isForceToStop,
                                                            @"id":idString,
                                                            @"mark":@"20"
                                                            } describe:markDescribe return:^(NSString *markString) {

            [array replaceObjectAtIndex:1 withObject:markString];
            
            NSString *newValue = [array componentsJoinedByString:@"/"];
            cell.vasLabel.text = newValue;
                                                                
            if (self.medicalRecordNum) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }

}
-(void)getStandardEvaluation{
    //获取评分标准
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/ScoreItem/List"] params:nil hasToken:YES success:^(HttpResponse *responseObject) {
        if ([responseObject.result intValue] == 1) {
            for (NSDictionary *dic in responseObject.content) {
                if ([[dic objectForKey:@"name"]isEqualToString:@"vas"]) {
                    markDescribe = dic[@"describe"];

                    break;
                }
            }
        }else{
            [SVProgressHUD showErrorWithStatus:responseObject.errorString];
        }
    } failure:nil];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ShowRecordDetail" sender:indexPath];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ShowRecordDetail"]) {
        RecordDetailViewController *controller = (RecordDetailViewController *)segue.destinationViewController;
        controller.patient = self.patient;
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        controller.record = [datas objectAtIndex:indexPath.row];
    }
}

@end
