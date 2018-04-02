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
#import <SVProgressHUD.h>

@interface TaskListViewController ()<UITableViewDelegate,UITableViewDataSource,QRCodeReaderDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@property (assign,nonatomic) NSInteger selectedRow;

@end

@implementation TaskListViewController

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
}

#pragma mark - table view delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 5;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TaskCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
    cell.scanButton.tag = indexPath.row;
    
    return cell;
    
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
        
        [SVProgressHUD showWithStatus:@"参数下发中……"];
        
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


@end
