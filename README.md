# AudioRecoderAndTransformMP3
iOS录制音频+距离感应+转MP3格式
---------------------------
1、录制音频首先配置音频参数，为了保证能转mp3格式：
---------------------------

```
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
```
录音过程不赘述直接调用方法：
```
/// 开始录音
/**
 开始录音

 @param name 文件名
 */
- (void)recordBeginWithName:(NSString *)name;
```
录音时间回调：
```
[ZYRecordTool sharedZYRecordTool].durationTimeBlock = ^(id time) {
                    self.time = [time intValue]；
         };
```

2、使用lame将caf转换成mp3格式，方便多端统一
---------------------------
```
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
```

3、距离感应+播放
---------
近距离改用听筒播放，并且熄灭屏幕。一般情况使用扬声器播放，屏幕不改变。
播放相关不赘述，设置距离感应：
```
//设置距离感应开启
     [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    //    监听距离
    if ([UIDevice currentDevice].proximityMonitoringEnabled == YES) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:)name:UIDeviceProximityStateDidChangeNotification object:nil];
        
    }
    //扬声器播放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
```

通知监听事件：
```
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

```

播放结束，或者终止播放一定记住要移除监听器，关闭距离感应：
```
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
     [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
}
```
