//
//  RecordModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "RecordModel.h"

@implementation RecordModel
-(instancetype)initWithDic:(NSDictionary *)dic{
    if (self = [super init]) {
        self.ID = dic[@"id"];
        self.time = (NSData *)[NSDate dateWithTimeIntervalSince1970:[dic[@"time"] doubleValue]];
        self.timeString =  [self stringFromTimeIntervalString:dic[@"time"] dateFormat:@"yyyy-MM-dd"];

        self.painfactorW = dic[@"painfactor_eng"];
        self.painArea = dic[@"painarea"];
        self.painfactorE = dic[@"painfactor_zh"];

        
        NSNumber *vasBeforeNum = dic[@"prescore"];
        self.vasBefore = [NSString stringWithFormat:@"%@",vasBeforeNum];
        NSNumber *vasAfterNum = dic[@"afterscore"];
        if ([vasAfterNum intValue] == -1) {
            self.vasAfter = @"？";
        }else{
            self.vasAfter = [NSString stringWithFormat:@"%@",vasAfterNum];
        }
        self.vasString = [NSString stringWithFormat:@"%@/%@",self.vasBefore,self.vasAfter];
        
        self.operator = dic[@"creator"];
        
        //治疗参数
        NSDictionary *treatParamDic = dic[@"treatargs"];
        NSNumber *type = treatParamDic[@"machinetype"];
        NSString *modeValue = treatParamDic[@"mode"];
        
        NSArray *dataArray = treatParamDic[@"lsargs"];
        
        NSMutableArray *params = [NSMutableArray arrayWithCapacity:20];
        
        switch ([type integerValue]) {
            case 56833:
            case 56834:
            case 56836:
            {
                Question *treatMode = [Question questionWithDic:@{@"showname":@"电流波形",@"value":modeValue}];
                [params addObject:treatMode];
                self.machineType = @"电疗";
            }

                break;
            case 7681:
            {
                Question *treatMode = [Question questionWithDic:@{@"showname":@"治疗模式",@"value":modeValue}];
                [params addObject:treatMode];
               self.machineType = @"空气波";
            }

                break;
            case 57119:
                self.machineType = @"血瘘";
                break;
            default:
                self.machineType = @"未知设备";
                break;
        }
        //物理治疗处方 设备（方案）
        self.physicalTreat = [NSString stringWithFormat:@"%@(%@)",self.machineType,dic[@"physicaltreatargs"] ];
        
        for (NSDictionary *dic in dataArray) {
            Question *param = [Question questionWithDic:dic];
            [params addObject:param];
            
        }
        self.treatParam = params;
    }
    return self;
}
-(void)appendQuestionsWithDic:(NSDictionary *)dic{

    if (![dic[@"answer_eng"]isEqual:[NSNull null]]) {
        self.questionW = [self transformQuestionArray: dic[@"answer_eng"]];
    }
    if (![dic[@"answer_zh"]isEqual:[NSNull null]]) {
        self.questionE = [self transformQuestionArray:dic[@"answer_zh"]];
    }
//    if ([dic[@"answer_eng"]isEqual:[NSNull null]] ||[dic[@"answer_zh"]isEqual:[NSNull null]]) {
//        
//    }else{
//        self.questionW = [self transformQuestionArray: dic[@"answer_eng"]];
//        self.questionE = [self transformQuestionArray:dic[@"answer_zh"]];
//    }
}

+(instancetype)modelWithDic:(NSDictionary *)dic{
    return [[self alloc]initWithDic:dic];
    
}
-(NSMutableArray *)transformQuestionArray:(NSArray *)questionArray
{
    NSMutableArray *array = [questionArray mutableCopy];
    
    for (NSDictionary *dic in questionArray) {
        
        NSMutableDictionary *copyDic = [dic mutableCopy];
        
        NSMutableArray *copyQuestions = [[NSMutableArray alloc]init];
        
        NSArray *questions = dic[@"value"];
        
        for (NSDictionary *dic in questions) {
            Question *question = [Question questionWithDic:dic];
            [copyQuestions addObject:question];
        }
        
        [copyDic setObject:copyQuestions forKey:@"value"];
        [copyDic setObject:dic[@"diagnosistype"] forKey:@"diagnosistype"];
        
        QuestionItem *item = [QuestionItem questionItemWithDic:copyDic];
        
        [array replaceObjectAtIndex:[array indexOfObject:dic] withObject:item];
        
    }
    return array;
}
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

@end

@implementation QuestionItem

+(instancetype)questionItemWithDic:(NSDictionary *)dic{
    QuestionItem *questionItem = [[QuestionItem alloc]init];
    questionItem.diagnosisType = dic[@"diagnosistype"];
    questionItem.questionArray = dic[@"value"];
    return questionItem;
}

@end

@implementation Question

+(instancetype)questionWithDic:(NSDictionary *)dic
{
    Question *question = [[Question alloc]init];
    question.name = dic[@"showname"];
    question.selectionString = dic[@"value"];
    if ([dic[@"value"]isEqualToString:@""]) {
        question.selectionString = @" ";
    }
    
    return question;
    
}

@end


