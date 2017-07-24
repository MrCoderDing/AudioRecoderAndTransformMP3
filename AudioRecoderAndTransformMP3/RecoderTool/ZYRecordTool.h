//
//  ZYRecordTool.h
//  ZYNaNian
//
//  Created by HenryVarro on 16/7/16.
//  Copyright © 2016年 ZYNaNian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ZHMacroDefinition.h"
typedef void (^didFinish)();




@interface ZYRecordTool : NSObject

@property (nonatomic, copy) didFinish finish;
///时长回调
@property (nonatomic, copy)voidBlock_id durationTimeBlock;
//已经确认
@property (nonatomic, assign)BOOL isConfirmed;
///录音器
@property (nonatomic, strong)AVAudioRecorder *audioRecorder;
///播放器
@property (nonatomic, strong)AVAudioPlayer *audioPlayer;

/// 录音单例
+ (instancetype)sharedZYRecordTool;

#pragma mark - 录制

/**
 开始录音

 @param name 文件名
 */
- (void)recordBeginWithName:(NSString *)name;

/// 停止录音 完成
- (BOOL)stopRecord;

///退出录音
- (void)quitRecord;


#pragma mark - 播放
/// 播放录音
- (void)playRecord;

///停止播放
- (void)stopPlayRecord;

///是否正在播放
- (BOOL)isPlaying;

/// 获取路径
- (NSURL *)getUrl;

// 获取总时间（秒）
- (NSString *)getRecordDurationTime;
- (NSString *)getSec;


//判断权限
-(BOOL)canRecord;

///清理录音
-(void)cleanUp;
@end
