//
//  RecordModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PatientModel.h"
@class QuestionItem;
@class Question;
@interface RecordModel : NSObject

@property (nonatomic,copy)NSString *ID;

@property (nonatomic,strong)PatientModel *patient;

//createtime
@property(nonatomic,strong)NSDate *time;

@property(nonatomic,copy)NSString *timeString;
//评分时间
@property(nonatomic,strong)NSDate *finishTime;

@property(nonatomic,copy)NSNumber *taskStateNumber;
//是否结束治疗
@property (nonatomic,assign)BOOL isFinished;

@property(nonatomic,copy)NSString *finishTimeString;

@property (nonatomic,strong)NSMutableArray <QuestionItem *> *questionW;

@property (nonatomic,strong)NSMutableArray <QuestionItem *> *questionE;

@property (nonatomic,copy)NSString *painfactorW;

@property (nonatomic,copy)NSString *painArea;

@property (nonatomic,copy)NSString *painfactorE;

@property (nonatomic,copy)NSString *physicalTreat;

@property (nonatomic,copy)NSString *machineType;

@property (nonatomic,copy)NSString *vasBefore;

@property (nonatomic,copy)NSString *vasAfter;

@property (nonatomic,copy)NSString *vasString;

@property (nonatomic,assign)BOOL hasImage;

//@property (nonatomic,strong)NSMutableDictionary*treatParam;
@property (nonatomic,copy)NSMutableArray<Question *>*treatParam;

@property (nonatomic,copy)NSString *operator;

+(instancetype)modelWithDic:(NSDictionary *)dic;

-(void)appendQuestionsWithDic:(NSDictionary *)dic;

@end

@interface QuestionItem : NSObject

@property (nonatomic,copy)NSString *diagnosisType;

@property (nonatomic,strong)NSMutableArray <Question *>*questionArray;

+(instancetype)questionItemWithDic:(NSDictionary *)dic;

@end


@interface Question:NSObject

@property (nonatomic,copy)NSString *name;

@property (nonatomic,copy)NSString *selectionString;


//-(instancetype)initWithDic:(NSDictionary *)dic;

+(instancetype)questionWithDic:(NSDictionary *)dic;

@end
