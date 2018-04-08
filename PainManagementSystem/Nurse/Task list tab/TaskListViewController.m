//
//  TaskListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TaskListViewController.h"
#import "TaskCell.h"
#import "SendTreatmentSuccessView.h"
#import "SendTreatmentFailView.h"
#import "QRCodeReaderViewController.h"
#import "PopoverTreatwayController.h"

#import "BaseHeader.h"
#import <SVProgressHUD.h>

#define ElectrotherapyTypeValue 56833
#define AirProTypeValue 7681
#define AladdinTypeValue 57119

#define ElectrothetapyColor 0x0dbaa5
#define AirProColor 0xfd8574
#define AladdinColor 0x5e97fe

@interface TaskListViewController ()<UITableViewDelegate,UITableViewDataSource,QRCodeReaderDelegate,UIPopoverPresentationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@property (assign,nonatomic) NSInteger selectedRow;

@end

@implementation TaskListViewController{
    NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self showSuccessView];
    [self initAll];

}
-(void)showSuccessView{
    [SVProgressHUD dismiss];
    [SendTreatmentSuccessView alertControllerAboveIn:self returnBlock:^{
        NSLog(@"send to server设置关注 ");
    }];
    

    
}

-(void)showFailView{
    [SVProgressHUD dismiss];
    [SendTreatmentFailView alertControllerAboveIn:self];
}

-(void)initAll{
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    NSArray *dataArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Task" ofType:@"plist"]];
    datas = [dataArray mutableCopy];
}


#pragma mark - table view delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TaskCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
    cell.scanButton.tag = indexPath.row;
    
    //治疗参数详情弹窗
    [cell.treatmentButton addTarget:self action:@selector(showPopover:) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *dataDic = datas[indexPath.row];
    cell.doctorNameLable.text = dataDic[@"creater"];
    cell.medicalRecordNumLable.text = dataDic[@"sickhistorynum"];
    cell.patientNameLabel.text = dataDic[@"patientname"];
    
    NSDictionary *physicalTreatDic = dataDic[@"physicaltreat"];
    NSString *type = physicalTreatDic[@"type"];
    switch ([type integerValue]) {
            
        case ElectrotherapyTypeValue:
            cell.typeLabel.text = @"电疗";
            [cell setTypeLableColor:UIColorFromHex(ElectrothetapyColor)];
            break;
            
        case AladdinTypeValue:
            cell.typeLabel.text = @"血瘘";
            [cell setTypeLableColor:UIColorFromHex(AladdinColor)];
            break;
            
        case AirProTypeValue:
            cell.typeLabel.text = @"空气波";
            [cell setTypeLableColor:UIColorFromHex(AirProColor)];
            break;
            
        default:
            break;
    }
    
    
    return cell;
    
}

-(void)showPopover:(UIButton *)sender {

    [self performSegueWithIdentifier:@"ShowPopover" sender:sender];
}

#pragma mark - scan
- (void)scanAction:(id)sender {
    
    self.selectedRow = [sender tag];
    
    NSArray *types = @[AVMetadataObjectTypeQRCode,
                       AVMetadataObjectTypeEAN13Code,
                       AVMetadataObjectTypeEAN8Code,
                       AVMetadataObjectTypeUPCECode,
                       AVMetadataObjectTypeCode39Code,
                       AVMetadataObjectTypeCode39Mod43Code,
                       AVMetadataObjectTypeCode93Code,
                       AVMetadataObjectTypeCode128Code,
                       AVMetadataObjectTypePDF417Code];
    
    _reader        = [QRCodeReaderViewController readerWithMetadataObjectTypes:types];
    
    // Using delegate methods
    _reader.delegate = self;
    
    
    [self presentViewController:_reader animated:YES completion:NULL];
    
}

#pragma mark - QRCodeReader Delegate Methods
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedRow inSection:0];
        
        [SVProgressHUD showWithStatus:@"处方下发中……"];
        
        //send treatment to server
        
        [self performSelector:@selector(showFailView) withObject:nil afterDelay:5.0];
        
        
        NSLog(@"QRretult == %@", result);
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)backToDeviceList:(id)sender {
    
    [self.navigationController popViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - prepareForSegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ShowPopover"]) {
        PopoverTreatwayController *destination = (PopoverTreatwayController *)segue.destinationViewController;
        UIPopoverPresentationController *popover = destination.popoverPresentationController;
        popover.delegate = self;
        
        //获取某个cell的数据
        UIView *contentView = [(UIView *)sender superview];
        
        TaskCell *cell = (TaskCell*)[contentView superview];
        
        NSIndexPath* index = [self.tableView indexPathForCell:cell];
        
        NSDictionary *dataDic = [datas objectAtIndex:index.row];
        NSDictionary *treatWayDic = dataDic[@"physicaltreat"][@"treatway"];
        
        destination.treatWayDic = treatWayDic;
        
        UIButton *button = sender;
        popover.sourceView = button;
        popover.sourceRect = button.bounds;
    }
}

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
