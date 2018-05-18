//
//  RecordDetailViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "RecordDetailViewController.h"
#import "RecordItemCell.h"
#import "QuestionCell.h"
#import "BaseHeader.h"
#import "RecordModel.h"

//image sdk
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Rotate.h"

#define KTitleViewHeight 48
#define KRowHeight 21
#define KRowInterval 18
#define KPartInterval 11

#define KWestTableViewTag 1111
#define KEastTableViewTag 2222
#define KTreatParamViewTag 3333

@interface RecordDetailViewController ()<UITableViewDataSource,UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic, strong) UIImagePickerController *picker;
@property (weak, nonatomic) IBOutlet UITableView *rootTableView;
@property (strong,nonatomic)RecordModel *recordModel;

//upload image
@property (strong,nonatomic)UIImage *image;

@end

@implementation RecordDetailViewController{
    NSMutableArray *titles;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    if(self.record.hasImage){
        NSString *api = [HTTPServerURLString stringByAppendingString:[NSString stringWithFormat:@"Api/TreatRecode/Treatimage?id=%@",self.record.ID]];
        
        //清除某一特定url的图片缓存
        [[SDImageCache sharedImageCache] removeImageForKey:api withCompletion:nil];
    }
    [self.rootTableView reloadData];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"诊疗记录详情";
    titles = [NSMutableArray arrayWithObjects:@"基本情况",@"西医病历采集",@"中医病历采集",@"诊断结果",@"物理治疗方法",@"设备治疗处方",@"治疗结果",nil];
    self.rootTableView.tableFooterView = [[UIView alloc]init];
    
    NSDictionary *dataDic = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Record" ofType:@"plist"]];
    


    //得到数据模型
    if (self.record) {
        self.recordModel = self.record;

    }else{
        self.recordModel = [RecordModel modelWithDic:dataDic];
    }
    
    //take photo
    if (self.picker == nil)
    {
        self.picker = [[UIImagePickerController alloc]init];
    }
    self.picker.delegate = self;
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
}

#pragma mark - tableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView == self.rootTableView) {
        if(self.recordModel.hasImage || self.image){
            return [titles count];
        }else{
            return [titles count] - 1;
        }

    }else if(tableView.tag == KWestTableViewTag){

        return [self.recordModel.questionW count];

    }else if(tableView.tag == KEastTableViewTag){

        return [self.recordModel.questionE count];
    }else {
        return 1;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.rootTableView) {
        return 1;
    }
    else if (tableView.tag == KWestTableViewTag){

        return [self.recordModel.questionW[section].questionArray count];
        
    }else if(tableView.tag == KEastTableViewTag){
        
        return [self.recordModel.questionE[section].questionArray count];
    }else if(tableView.tag == KTreatParamViewTag){
        return [self.recordModel.treatParam count];
    }else{
        return 1;
    }

}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.rootTableView) {
        //基本情况
        if (indexPath.section == [titles indexOfObject:@"基本情况"]) {
//            return 4*KRowInterval+3*KRowHeight+KTitleViewHeight+KPartInterval;
            return UITableViewAutomaticDimension;
        }
        //诊断结果
        if ((indexPath.section == [titles indexOfObject:@"诊断结果"]) || (indexPath.section == [titles indexOfObject:@"物理治疗方法"])) {
//            return 2*KRowInterval+1*KRowHeight+KTitleViewHeight+KPartInterval;
            return UITableViewAutomaticDimension;
        }
        //西医病历采集
        if (indexPath.section == [titles indexOfObject:@"西医病历采集"]) {
            return [self rowHeightWithQuestionArray:self.recordModel.questionW];
        }
        if (indexPath.section == [titles indexOfObject:@"中医病历采集"]) {
            return [self rowHeightWithQuestionArray:self.recordModel.questionE];
        }
        if (indexPath.section == [titles indexOfObject:@"设备治疗处方"]) {
            return 44*([self.recordModel.treatParam count])+KTitleViewHeight +KPartInterval+KRowInterval*2;
        }
    }else if(tableView.tag == KWestTableViewTag){

            return UITableViewAutomaticDimension;

    }else if (tableView.tag == KEastTableViewTag){  //中医病历采集
            return UITableViewAutomaticDimension;
    }
    return UITableViewAutomaticDimension;

}
-(NSInteger)rowHeightWithQuestionArray:(NSMutableArray *)array{
    
    NSInteger sectionNumber = [array count];
    NSMutableArray <QuestionItem*> *quetionItemArray = array;
    NSInteger rowNumber = 0;
    //自动分行行数 每多加一行增加高度18
    NSInteger extralRowNum = 0;
    for (QuestionItem *item in quetionItemArray) {
        NSMutableArray <Question *>*questionArray = item.questionArray;
        for (Question *question in questionArray) {
            if ([question.selectionString length]>18) {
                extralRowNum ++;
            }
        }
        rowNumber += [item.questionArray count];
        
    }
    return 44*(sectionNumber + rowNumber)+extralRowNum * 18 + KTitleViewHeight+KPartInterval+KRowInterval;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier;
    if (tableView == self.rootTableView) {
        switch (indexPath.section) {
                
            case 0: {   CellIdentifier = @"BasicInfomationCell";    }       break;
            case 3: {   CellIdentifier = @"ResultCell";     }
            case 4: {   CellIdentifier = @"ResultCell";     }       break;
            case 6: {   CellIdentifier = @"PhotoCell" ;     }       break;
            default: {      CellIdentifier = @"Cell";       }       break;
        }
        
        RecordItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[RecordItemCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        //roottableview每个section的标题
        cell.titleLabel.text = titles[indexPath.section];
        

        switch (indexPath.section) {
            case 0:
            {
                cell.medicalNumLabel.text = [NSString stringWithFormat:@"病历号：%@",self.patient.medicalRecordNum];
                NSString *name = [self CharacterStringMainString:[NSString stringWithFormat:@"姓名：%@",self.patient.name] AddDigit:20 AddString:@"  "];
                NSString *age = [self CharacterStringMainString:[NSString stringWithFormat:@"年龄：%@",self.patient.age] AddDigit:20 AddString:@"  "];
                cell.patientLabel.text = [NSString stringWithFormat:@"%@%@电话：%@",name,age,self.patient.contact];
                
                NSString *vasBefore = [self CharacterStringMainString:[NSString stringWithFormat:@"治疗前vas：%@",self.recordModel.vasBefore] AddDigit:20 AddString:@"  "];
                NSString *vasAfter = [self CharacterStringMainString:[NSString stringWithFormat:@"治疗后vas：%@",self.recordModel.vasAfter] AddDigit:20  AddString:@"  "];
                cell.vasLabel.text = [NSString stringWithFormat:@"%@%@医生：%@",vasBefore,vasAfter,self.recordModel.operator];
                return cell;
            }
                break;
            case 1:
            {
                cell.insertTableView.tag = KWestTableViewTag;
                 [cell.insertTableView reloadData];
            }
                break;
            case 2:
            {
                cell.insertTableView.tag = KEastTableViewTag;
                [cell.insertTableView reloadData];
            }
                break;
            case 3:
            {
                cell.contentLabel.text = [NSString stringWithFormat:@"病理因素：%@          发病部位：%@         中医辨证：%@",self.recordModel.painfactorW,self.recordModel.painArea,self.recordModel.painfactorE];
                
                cell.contentLabel.numberOfLines = 0;
                cell.contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
                
                return cell;
            }
                break;
            case 4:
            {
                
                cell.contentLabel.text = [NSString stringWithFormat:@"%@",self.recordModel.physicalTreat];
                
                return cell;
            }
                break;
            case 5:
            {
                cell.insertTableView.tag = KTreatParamViewTag;
                [cell.insertTableView reloadData];

            }
                break;
            case 6:
            {

                //治疗结果照片
                if (self.image) {
                    cell.resultImageView.image = self.image;
                }else{

                    if(self.record.hasImage){

                        NSString *api = [HTTPServerURLString stringByAppendingString:[NSString stringWithFormat:@"Api/TreatRecode/Treatimage?id=%@",self.record.ID]];

                        [cell.resultImageView sd_setImageWithURL:[NSURL URLWithString:api]
                                     placeholderImage:[UIImage imageNamed:@"placeholder.png"]];

                    }
                }
                
            }
                break;
            default: {
//                CellIdentifier = @"Cell";
                
            }
                break;
        }
           return cell;
    }else {
        
        CellIdentifier = @"QuestionCell";
        QuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[QuestionCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSMutableArray *dataArray = [[NSMutableArray alloc]init];
        //西医病历采集
        if (tableView.tag == KWestTableViewTag)
        {
            dataArray = self.recordModel.questionW;

            
        }
        else if (tableView.tag == KEastTableViewTag)
        {  //中医病历采集
            dataArray = self.recordModel.questionE;
            
        }
        else if(tableView.tag == KTreatParamViewTag)
        {
            //物理治疗方法
            Question *param = self.recordModel.treatParam[indexPath.row];
            cell.questionNameLabel.text = param.name;
            cell.selectionsLabel.text = param.selectionString;
        }
        
        if([dataArray count]>0){
            
            QuestionItem *questionItem = dataArray[indexPath.section];
            if (indexPath.row < [questionItem.questionArray count]) {
                
                Question *question = questionItem.questionArray[indexPath.row];
                
                cell.questionNameLabel.text = question.name;
                
                cell.selectionsLabel.text = question.selectionString;
            }
            
        }

        return cell;
        
    }

}

#pragma mark -sectionStyle
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView != self.rootTableView) {
        if (tableView.tag == KTreatParamViewTag) {
            return KRowInterval;
        }
        return 44;
    }
    return 0;
}
//返回每组头部view
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *headerView = [[UIView alloc]init];
    
    if ((tableView != self.rootTableView) && (tableView.tag != KTreatParamViewTag)) {
        
        UILabel *label = [[UILabel alloc]init];
        
        label.textColor = [UIColor grayColor];
        
        label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightLight];
        
        label.frame = CGRectMake(30, 0, 100, 44);
        
        [headerView addSubview:label];
        
        NSMutableArray *dataArray = [[NSMutableArray alloc]init];
        
        if (tableView.tag == KWestTableViewTag) {

            dataArray = self.recordModel.questionW;
            
        }else if (tableView.tag == KEastTableViewTag){

            dataArray = self.recordModel.questionE;
            
        }
        
            NSMutableArray *typeNames = [[NSMutableArray alloc]initWithCapacity:20];;
        
        
        for (QuestionItem *questionItem  in dataArray) {
            
            NSString *typeName = questionItem.diagnosisType;
            
            [typeNames addObject:typeName];
        }
        
        if ([typeNames count ]>section) {
            label.text = typeNames[section];
        }
    }
    
    return headerView;
    
}
#pragma mark字符串自动补充方法

- (NSString*)CharacterStringMainString:(NSString*)MainString AddDigit:(int)AddDigit AddString:(NSString*)AddString
{
    
    for(int i = 0; i < MainString.length; i++)
    {
        if(AddDigit == 0){
            break;
        }
        unichar ch = [MainString characterAtIndex:i];
        
        if ((0x4e00 < ch  && ch < 0x9fff) || ch == 0xff1a || ch == 0xff1f)
        {
            //若为汉字 中文问号 中文冒号

            AddDigit = AddDigit - 2;
        } else
        {

            AddDigit = AddDigit - 1;
        }

    }

    NSString *ret = [[NSString alloc]init];

    ret = MainString;

    for(int y =0;y < AddDigit ;y++ ){

        ret = [NSString stringWithFormat:@"%@%@",ret,AddString];

    }

    return ret;

}
- (IBAction)uploadImage:(id)sender {
    if(self.image){
        NSString *api = [HTTPServerURLString stringByAppendingString:[NSString stringWithFormat:@"Api/TreatRecode/AddImage?token=%@&id=%@",Token,self.record.ID]];
        
        [[NetWorkTool sharedNetWorkTool]POST:api
                                       image:self.image success:^(HttpResponse *responseObject) {
                                           if ([responseObject.result intValue] == 1) {
                                               [SVProgressHUD showSuccessWithStatus:@"治疗照片已保存"];
                                           }else{
                                               [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                           }
                                       } failure:nil];
    }
}
-(UIImage *) getImageFromURL:(NSString *)fileURL
{
    
    UIImage * result;
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]];
    result = [UIImage imageWithData:data];
    return result;
}
#pragma mark - addPhoto
- (IBAction)addPhoto:(id)sender {
//    if (self.record.hasImage) {
//        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
//                                                                       message:@"该治疗疗程记录已经有治疗后照片，是否重新拍摄照片？"
//                                                                preferredStyle:UIAlertControllerStyleAlert];
//
//        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
//                                                             handler:^(UIAlertAction * action) {}];
//        [alert addAction:cancelAction];
//
//        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//
//            [self presentViewController:self.picker animated:YES completion:NULL];
//        }];
//
//        [alert addAction:okAction];
//        [self presentViewController:alert animated:YES completion:nil];
//
//    }else{
        [self presentPhotoLibraryOrCamera];
//    }
}
-(void)presentPhotoLibraryOrCamera{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];

    //按钮：拍照，类型：UIAlertActionStyleDefault
    [alert addAction:[UIAlertAction actionWithTitle:@"拍照"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action){
                                                UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
                                                //获取方式:通过相机
                                                PickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
                                                PickerImage.allowsEditing = NO;
                                                PickerImage.delegate = self;
                                                self.picker = PickerImage;
                                                [self presentViewController:self.picker animated:YES completion:nil];
                                            }]];
    
    //按钮：从相册选择，类型：UIAlertActionStyleDefault
    [alert addAction:[UIAlertAction actionWithTitle:@"从相册选择"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                UIImagePickerController *pickerImage = [[UIImagePickerController alloc]init];
                                                pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                                pickerImage.allowsEditing = YES;
                                                pickerImage.delegate = self;
                                                self.picker = pickerImage;
                                                [self presentViewController:self.picker animated:YES completion:nil];
                                            }]];
    
    
    //按钮：取消，类型：UIAlertActionStyleCancel
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{

    [self.picker dismissViewControllerAnimated:YES completion:NULL];
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    //获取图片
    UIImage *image = [[info objectForKey:UIImagePickerControllerOriginalImage]fixOrientation];

    self.image = image;



    [self.picker dismissViewControllerAnimated:YES completion:^{

    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.rootTableView reloadData];
        
    });
}


@end
