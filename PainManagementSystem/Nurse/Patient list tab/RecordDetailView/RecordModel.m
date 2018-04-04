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
    self = [super init];
    return self;
}

+(instancetype)recordModelWithDic:(NSDictionary *)dic{
    

    RecordModel *record = [[RecordModel alloc]init];
    record.questionW = [record transformQuestionArray: dic[@"questionw"]];
    record.questionE = [record transformQuestionArray:dic[@"questione"]];
//    record.questionW = dic[@"questionw"];
//    record.questionE = dic[@"questione"];
    record.painfactorW = dic[@"painfactorw"];
    record.painArea = dic[@"painarea"];
    record.painfactorE = dic[@"painfactore"];
    record.physicalTreat = dic[@"physicaltreat"];
    record.vasBefore = dic[@"vasbefore"];
    record.vasAfter = dic[@"vasafter"];
    record.treatParam = dic[@"treatparam"];
    record.operator = dic[@"operator"];
    return record;
}
-(NSMutableArray *)transformQuestionArray:(NSArray *)questionArray
{
    NSMutableArray *array = [questionArray mutableCopy];
    
    for (NSDictionary *dic in questionArray) {
        
        NSMutableDictionary *copyDic = [dic mutableCopy];
        
        NSMutableArray *copyQuestions = [[NSMutableArray alloc]init];
        
        NSArray *questions = dic[@"question"];
        
        for (NSDictionary *dic in questions) {
            Question *question = [Question questionWithDic:dic];
            [copyQuestions addObject:question];
        }
        
        [copyDic setObject:copyQuestions forKey:@"question"];
        
        QuestionItem *item = [QuestionItem questionItemWithDic:copyDic];
        
        [array replaceObjectAtIndex:[array indexOfObject:dic] withObject:item];
        
    }
    return array;
}

@end

@implementation QuestionItem

+(instancetype)questionItemWithDic:(NSDictionary *)dic{
    QuestionItem *questionItem = [[QuestionItem alloc]init];
    questionItem.diagnosisType = dic[@"diagnosistype"];
    questionItem.questionArray = dic[@"question"];
    return questionItem;
}

@end

@implementation Question

+(instancetype)questionWithDic:(NSDictionary *)dic
{
    Question *question = [[Question alloc]init];
    question.name = dic[@"name"];
    question.isMultiSelect = dic[@"ismultiselect"];
    question.selectionArray = dic[@"selection"];
    NSMutableString *string = [[NSMutableString alloc]init];
    for (NSString *selection in question.selectionArray) {
        if (selection != question.selectionArray.lastObject) {
            [string appendFormat:@"%@、",selection];
        }else{
            [string appendFormat:@"%@",selection];
        }
    }
    question.selectionString = [string copy];
    return question;
    
}
@end


