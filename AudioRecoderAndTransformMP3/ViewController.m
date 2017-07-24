//
//  ViewController.m
//  AudioRecoderAndTransformMP3
//
//  Created by HenryVarro on 2017/7/21.
//  Copyright © 2017年 丁子恒. All rights reserved.
//

#import "ViewController.h"
#import "ZYRecordTool.h"


typedef enum : NSUInteger {
    ZYRecordTypeBegin = 1,  //还未开始
    ZYRecordTypeFinish,     //录制完成
    ZYRecordTypePlaying,    //播放中
    ZYRecordTypeRecording   //录制中
} ZYRecordType;

@interface ViewController ()

@property (nonatomic, assign) ZYRecordType recordType;
@property (nonatomic, assign) int time;
@end

@implementation ViewController


- (void)setTime:(int)time{
    _time = time;
     self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", time/3600,time%3600 / 60, time % 60];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.recordType = ZYRecordTypeBegin;
    // Do any additional setup after loading the view, typically from a nib.
}



#pragma mark - 功能按钮点击
- (IBAction)actionBtnClicked:(id)sender {
    
    NSString *btnTitle = @"Record";
    switch (_recordType) {
        case ZYRecordTypeBegin:{
            
            if([[ZYRecordTool sharedZYRecordTool] canRecord]){
                [[ZYRecordTool sharedZYRecordTool] recordBeginWithName:@"test"];
                
                [ZYRecordTool sharedZYRecordTool].durationTimeBlock = ^(id time) {
                
                    self.time = [time intValue];
                };
                btnTitle = @"Stop";
                self.recordType = ZYRecordTypeRecording;
                break;
                
            }else{
                NSLog(@"Error :请开启录音权限");
                
                break;
            }
        }
        case ZYRecordTypeFinish:{
            [[ZYRecordTool sharedZYRecordTool] playRecord];
            
            [ZYRecordTool sharedZYRecordTool].finish = ^{
            
                
                [self.actionBtn setTitle:@"Play" forState:UIControlStateNormal];
                self.recordType = ZYRecordTypeFinish;
                
            };
            btnTitle = @"Stop";
            self.recordType = ZYRecordTypePlaying;
            
        }
            break;
        case ZYRecordTypePlaying:{
            [[ZYRecordTool sharedZYRecordTool] stopPlayRecord];
            btnTitle = @"Play";
            self.recordType = ZYRecordTypeFinish;
            
        }
            break;
        case ZYRecordTypeRecording:{
            if([[ZYRecordTool sharedZYRecordTool] stopRecord]){
                btnTitle = @"Play";
                self.recordType = ZYRecordTypeFinish;
            }else{
                NSLog(@"时间太短了");
                self.recordType = ZYRecordTypeBegin;
                
            }
            self.time = 0;
            
        }
            break;
        default:
            break;
    }
    [self.actionBtn setTitle:btnTitle forState:UIControlStateNormal];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
