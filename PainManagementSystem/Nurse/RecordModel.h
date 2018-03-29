//
//  RecordModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QuestionItem;
@interface RecordModel : NSObject

@property (nonatomic,strong)NSMutableArray <QuestionItem *> *questionW;

@property (nonatomic,strong)NSMutableArray <QuestionItem *> *questionE;

@property (nonatomic,copy)NSString *painfactorW;

@property (nonatomic,copy)NSString *painArea;

@property (nonatomic,copy)NSString *painfactorE;

@property (nonatomic,copy)NSString *physicalTreat;

@property (nonatomic,copy)NSString *vasBefore;

@property (nonatomic,copy)NSString *vasAfter;

@property (nonatomic,strong)NSMutableDictionary*treatParam;

@property (nonatomic,copy)NSString *operator;

+(instancetype)recordModelWithDic:(NSDictionary *)dic;

@end


@class Question;

@interface QuestionItem : NSObject

@property (nonatomic,copy)NSString *diagnosisType;

@property (nonatomic,strong)NSMutableArray <Question *>*questionArray;

//-(instancetype)initWithDic:(NSDictionary *)dic;

+(instancetype)questionItemWithDic:(NSDictionary *)dic;

@end


@interface Question:NSObject

@property (nonatomic,copy)NSString *name;

@property (nonatomic,assign)BOOL isMultiSelect;

@property (nonatomic,strong)NSArray *selectionArray;

@property (nonatomic,copy)NSString *selectionString;

@property (nonatomic,strong)NSMutableDictionary *dataDic;

//-(instancetype)initWithDic:(NSDictionary *)dic;

+(instancetype)questionWithDic:(NSDictionary *)dic;

@end
