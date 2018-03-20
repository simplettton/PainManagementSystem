//
//  AddDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "DeviceTableViewCell.h"
@interface AddDeviceViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation AddDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)backToDeviceList:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:YES];
    self.title = @"设备管理系统";
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
}

#pragma mark - tableview dataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[DeviceTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
//    NSDictionary *dataDic = [datas objectAtIndex:indexPath.row];
//    cell.typeLabel.text = [dataDic objectForKey:@"type"];
//    cell.macLabel.text = [dataDic objectForKey:@"mac"];
//    cell.nameLabel.text = [dataDic objectForKey:@"name"];
//    cell.serialNum = [dataDic objectForKey:@"serialNum"];
    
//    cell.editButton.tag = indexPath.row;
//    [cell.editButton addTarget:self action:@selector(edit:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
}

@end
