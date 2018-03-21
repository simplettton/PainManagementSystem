//
//  AddDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "AddDeviceCell.h"
#import "BaseHeader.h"
typedef NS_ENUM(NSUInteger,typeTags)
{
    electrotherapyTag = 1000,airProTag = 1001,aladdinTag = 1002
};
@interface AddDeviceViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (assign,nonatomic) NSInteger selectedTag;
@end

@implementation AddDeviceViewController{
    NSMutableArray *datas;
}
- (IBAction)changeDevice:(UIButton *)sender {
    self.selectedTag = [sender tag];
    
    
    for (int i = electrotherapyTag; i<electrotherapyTag +3; i++) {
        UIButton *btn = (UIButton *)[self.contentView viewWithTag:i];
        //配置选中按钮
        if ([btn tag] == [(UIButton *)sender tag]) {
            btn.backgroundColor = UIColorFromHex(0x37bd9c);
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }else{
            btn.backgroundColor = [UIColor whiteColor];
            [btn setTitleColor:UIColorFromHex(0x212121) forState:UIControlStateNormal];
        }
    }
    
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
    
    // Do any additional setup after loading the view.
}

-(void)initAll{
    self.tableView.tableFooterView = [[UIView alloc]init];
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    datas = [NSMutableArray arrayWithObjects:
             @{@"type":@"空气波",@"macString":@"dgahqaa",@"name":@"骨科一号",@"serialNum":@"13654979946"},
             @{@"type":@"空气波",@"macString":@"fjfjfds",@"name":@"骨科一号",@"serialNum":@"45645615764"},
             @{@"type":@"电疗",@"macString":@"fstjkst",@"name":@"骨科一号",@"serialNum":@"12367874456"},
             nil];
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
    return [datas count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    AddDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[AddDeviceCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *dataDic = [datas objectAtIndex:indexPath.row];
//    cell.ringButton.titleLabel.text = [dataDic objectForKey:@"macString"];
//    [cell.ringButton.titleLabel setText:[dataDic objectForKey:@"macString"]];
    [cell.ringButton setTitle:[dataDic objectForKey:@"macString"] forState:UIControlStateNormal];
    cell.ringButton.tag = indexPath.row;
//    [cell.ringButton addTarget:self action:@selector(ring:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
}

@end
