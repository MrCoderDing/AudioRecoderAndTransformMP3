//
//  ZYRecordTool.m
//  ZYNaNian
//
//  Created by HenryVarro on 16/7/16.
//  Copyright © 2016年 ZYNaNian. All rights reserved.
//

#import "ZYRecordTool.h"
#import "lame.h"
#import <UIKit/UIKit.h>
@interface ZYRecordTool ()<AVAudioPlayerDelegate>


// 定时器
@property (nonatomic, strong) CADisplayLink *link;
// 计时器
@property (nonatomic,assign) CGFloat timePass;

@end

@implementation ZYRecordTool {
    NSString *fileName;
    NSURL* recordUrl;
    NSURL* mp3FilePath;
    NSURL* audioFileSavePath;
    
    CGFloat time;
}

#pragma mark - 转换mp3
- (void)transformCAFToMP3 {
    NSString *name = [NSString stringWithFormat:@"%@.mp3", fileName];
    mp3FilePath = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:name]];
    
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([[recordUrl absoluteString] cStringUsingEncoding:1], "rb");   //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                                   //skip file header
        FILE *mp3 = fopen([[mp3FilePath absoluteString] cStringUsingEncoding:1], "wb"); //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        audioFileSavePath = mp3FilePath;
        NSLog(@"MP3生成成功: %@",audioFileSavePath);
    }
}

+ (instancetype)sharedZYRecordTool {
    
    static ZYRecordTool *_sharedZYRecordTool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedZYRecordTool = [[self alloc] init];
    });
    
    return _sharedZYRecordTool;
}

- (void)recordBeginWithName:(NSString *)name {
    fileName = name;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&setCategoryError];
    

    if(setCategoryError){
        NSLog(@"%@", [setCategoryError description]);
    }
    
    
    // 1.1获取路径,保存
    NSString *localFileName = [NSString stringWithFormat:@"%@.caf", name];
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:localFileName];
    
    NSLog(@"%@",path);
    
    recordUrl = [NSURL URLWithString:path];
    
    NSError *error = nil;
    
    //录音设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）, 采样率必须要设为11025才能使转化成mp3格式后不会失真
    [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    //录音通道数  1 或 2 ，要转换成mp3格式必须为双通道
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:path] settings:recordSetting error:&error];
    
    if (error) {
        NSLog(@"创建一个录音对象出错:%@",error);
        return;
    }
    // 2.准备录音
    [_audioRecorder prepareToRecord];
    
    // 开启表盘,绘制分贝数
    _audioRecorder.meteringEnabled = YES;
    
    [self startRecord];
}

#pragma mark - 处理监听 距离感应
-(void)sensorStateChange:(NSNotificationCenter *)notification;

{
    
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗
    if ([[UIDevice currentDevice] proximityState] == YES){
        
        NSLog(@"Device is close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
    }else{
        
        NSLog(@"Device is not close to user");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
}

// 录音
- (void)startRecord {
    
    time = 0;
    
    // 3.录音
    [_audioRecorder record];
    [self turnOnLink];
}
//// 暂停
//- (void)pauseRecord {
//    [self.recorder pause];
//}
// 停止
- (BOOL)stopRecord {
    
    [_audioRecorder stop];
    
    [self.link invalidate];
    self.link = nil;
    
    if (time < 1) {
        [[NSFileManager defaultManager]removeItemAtURL:[[ZYRecordTool sharedZYRecordTool] getUrl] error:nil];
        recordUrl = nil;
        return NO;
    }
    [self transformCAFToMP3];
    return YES;
}
- (void)quitRecord{
    [_audioRecorder stop];
    [self.link invalidate];
    self.link = nil;
}
- (void)turnOnLink{
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWithLink)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

// 随着定时器,时时更新的方法
- (void)updateWithLink{
   
    //计时器
    time += 1 / 60.0;
    if (self.durationTimeBlock) {
        self.durationTimeBlock(@(time));
    }
    
    // 时时监听
    [_audioRecorder updateMeters];
    
    // 声道(-100 ~ 0)
    float power = [_audioRecorder averagePowerForChannel:0];
    
    NSLog(@"time:%f power:%f",time,power);
}


#pragma - mark 播放
- (void)playRecord {
    
    //设置距离感应开启
     [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    //    监听距离
    if ([UIDevice currentDevice].proximityMonitoringEnabled == YES) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:)name:UIDeviceProximityStateDidChangeNotification object:nil];
        
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    NSError *error;
    if (mp3FilePath != nil) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:mp3FilePath error:&error];
    }
    else if (recordUrl != nil){
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordUrl error:&error];
    }
    
    
    if (error) {
        NSLog(@"创建一个播放音乐的对象出错:%@",error);
        return;
    }
    
    _audioPlayer.delegate = self;
    // 2.准备播放
    [_audioPlayer prepareToPlay];
    [self startPlayRecord];
}

// 播放
- (void)startPlayRecord {
    time = 0;
    
    [self turnOnLink];
    [_audioPlayer play];
}
// 停止
- (void)stopPlayRecord {
    [_audioPlayer stop];
    [self.link invalidate];
    self.link = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
}
// 是否在播放
- (BOOL)isPlaying {
    return _audioPlayer.playing;
}
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    if (self.finish) {
        self.finish();
    }
    time = 0;
    if (self.durationTimeBlock) {
        self.durationTimeBlock(@(time));
    }
    self.finish = nil;
    [self.link invalidate];
    self.link = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
     [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
}

#pragma mark - 获取路径
- (NSURL *)getUrl {
    return mp3FilePath;
}


- (NSString *)getSec {
    if (recordUrl == nil && mp3FilePath == nil) {
        
        return nil;
    }
    NSError *error = nil;
    
    if (mp3FilePath != nil) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:mp3FilePath error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
        return [NSString stringWithFormat:@"%d", (int)_audioPlayer.duration];
    }
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordUrl error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    return [NSString stringWithFormat:@"%f", _audioPlayer.duration];
}

- (NSString *)getRecordDurationTime {
    if (recordUrl == nil && mp3FilePath == nil) {
        
        return nil;
    }
    
    NSError *error = nil;
    
    
    
    if (mp3FilePath != nil) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:mp3FilePath error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
        return [self stringWithTimeInterval:_audioPlayer.duration];
    }
    
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordUrl error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    return [self stringWithTimeInterval:_audioPlayer.duration];
}


#pragma mark - 时间间隔  转 字符串
- (NSString *)stringWithTimeInterval:(NSTimeInterval)time{
    // 获取分钟
    //    int minute = time / 60;
    // 获取秒
    
    NSInteger second = time;// % 60;
    if (second == 0) {
        second = (int)_audioPlayer.duration;
    }
    //”’
    return [NSString stringWithFormat:@"%ld”", (long)second];
    
}
-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                bCanRecord = YES;
            }
            else {
                bCanRecord = NO;
            }
        }];
    }
    
    return bCanRecord;
}
- (void)cleanUp{
    [[ZYRecordTool sharedZYRecordTool] stopPlayRecord];
    [[NSFileManager defaultManager]removeItemAtURL:[[ZYRecordTool sharedZYRecordTool] getUrl] error:nil];
    [[ZYRecordTool sharedZYRecordTool]setValue:nil forKey:@"recordUrl"];
    [[ZYRecordTool sharedZYRecordTool]setValue:nil forKey:@"mp3FilePath"];
    [ZYRecordTool sharedZYRecordTool].isConfirmed = NO;
}
@end
