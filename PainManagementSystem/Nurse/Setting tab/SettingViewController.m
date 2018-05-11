//
//  SettingViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/23.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "SettingViewController.h"
#import "BaseHeader.h"
#import "ContactServiceView.h"
#import "LoginViewController.h"
typedef NS_ENUM(NSUInteger,typeTags)
{
    imageTag = 1000,nameTag = 1001
};
@interface SettingViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *hospitalLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *departmentLabel;
- (IBAction)edit:(id)sender;

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self setBorderWithView:self.nameLabel top:NO left:YES bottom:NO right:YES borderColor:[UIColor whiteColor] borderWidth:1.0];

}
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
    
    self.hospitalLabel.text = [UserDefault objectForKey:@"Hospital"];
    self.nameLabel.text = [UserDefault objectForKey:@"PersonName"];
    self.phoneLabel.text = [UserDefault objectForKey:@"Contact"];
//    self.userNameLabel.text = [UserDefault objectForKey:@"UserName"];
    self.userNameLabel.text = [NSString stringWithFormat:@"%@    %@",[UserDefault objectForKey:@"UserName"],[UserDefault objectForKey:@"Department"]];
//    self.departmentLabel.text = [UserDefault objectForKey:@"Department"];

}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)setBorderWithView:(UIView *)view top:(BOOL)top left:(BOOL)left bottom:(BOOL)bottom right:(BOOL)right borderColor:(UIColor *)color borderWidth:(CGFloat)width
{
    if (top) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (left) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (bottom) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, view.frame.size.height - width, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (right) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(view.frame.size.width - width, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
}
#pragma mark - tableview delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 0){
        return 2;
    }
        return 1;

}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    NSArray *imageNames = @[@"key",@"phone",@""];
    NSArray *titles = @[@"修改密码",@"联系客服",@"退出登录"];
    
    UIImageView *imageView = [cell viewWithTag:imageTag];
    UILabel *nameLabel = [cell viewWithTag:nameTag];
    
    imageView.image = [UIImage imageNamed:imageNames[indexPath.row+indexPath.section *2]];
    nameLabel.text = titles[indexPath.row+indexPath.section *2];
    if (indexPath.row+indexPath.section*2 == 2) {
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.textColor = UIColorFromHex(0x03B8EE);
    }
    
    
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section *2 +indexPath.row == 0) {
        [self performSegueWithIdentifier:@"EditPassword" sender:nil];
    }
    else if (indexPath.section *2 +indexPath.row == 1) {
        [ContactServiceView alertControllerAboveIn:self];
    }
    else if (indexPath.section *2 +indexPath.row == 2){
        
  
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:@"退出后不会删除任何历史数据，下次登录依然可以使用本账号。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:cancelAction];
        
        UIAlertAction* logoutAction = [UIAlertAction actionWithTitle:@"退出登录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

            [UserDefault setBool:NO forKey:@"IsLogined"];
            
            [UserDefault synchronize];
            
            [[[UIApplication sharedApplication].delegate window].rootViewController removeFromParentViewController];
            
            UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            
            LoginViewController *vc = (LoginViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [UIView transitionWithView:[[UIApplication sharedApplication].delegate window]
                              duration:0.25
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                            [[UIApplication sharedApplication].delegate window].rootViewController = vc;
                            }
                            completion:nil];

            [self presentViewController:vc animated:YES completion:nil];
            
            [[[UIApplication sharedApplication].delegate window] makeKeyAndVisible];
        }];
        
        [alert addAction:logoutAction];
        [self presentViewController:alert animated:YES completion:nil];
        

    }
}
- (IBAction)edit:(id)sender {
}

@end
