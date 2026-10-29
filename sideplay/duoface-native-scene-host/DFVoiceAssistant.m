// Voice commands are explicitly activated by the user in DuoFace on iPhone.
// They never take over system Siri, CarPlay sound focus or navigation scenes.
#import "DFVoiceAssistant.h"
#import "DFExtendedSettingsPolicy.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
#import <math.h>
@interface DFVoiceAssistant ()
@property(nonatomic,strong) SFSpeechRecognizer *recognizer;
@property(nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *request;
@property(nonatomic,strong) SFSpeechRecognitionTask *task;
@property(nonatomic,strong) AVAudioEngine *engine;
@property(nonatomic,strong) AVSpeechSynthesizer *speaker;
@property(nonatomic,copy) void (^done)(NSString *);
@property(nonatomic,assign) NSUInteger generation;
@property(nonatomic,assign) BOOL ownsVoiceAudioSession;
@property(nonatomic,assign,readwrite,getter=isListening) BOOL listening;
@end
@implementation DFVoiceAssistant
- (instancetype)init {
 if((self=[super init]))_speaker=[AVSpeechSynthesizer new];
 return self;
}
- (void)stop {
 ++self.generation;
 if(self.engine.isRunning)[self.engine stop];
 if(self.engine){
   @try {[[self.engine inputNode] removeTapOnBus:0];}
   @catch(__unused NSException *error){}
 }
 [self.request endAudio];[self.task cancel];self.task=nil;
 self.request=nil;self.engine=nil;self.listening=NO;self.done=nil;
 // Never leave a CarPlay music ducking session active.
 if(self.ownsVoiceAudioSession) {
   self.ownsVoiceAudioSession=NO;
   [[AVAudioSession sharedInstance] setActive:NO
       withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
 }
}
- (NSString *)voiceReply:(NSString *)input {
 NSString *text=[input lowercaseString];
 BOOL english=[DFCurrentExtended()[@"Language"] isEqualToString:@"en"];
 if([text containsString:@"dock"]){
    NSDictionary *session=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist"];
    NSDictionary *ack=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.ack.plist"];
    double now=NSDate.date.timeIntervalSince1970;
    double age=now-[session[@"Timestamp"] doubleValue];
    double ackAge=now-[ack[@"Timestamp"] doubleValue];
    BOOL valid=[session[@"Active"] isEqual:@YES] &&
       [session[@"Session"] isKindOfClass:NSString.class] &&
       [ack[@"Session"] isEqual:session[@"Session"]] &&
       [ack[@"DockOwnerVerified"] isEqual:@YES] &&
       [ack[@"Applied"] isEqual:@YES] &&
       age>=0&&age<=2.5&&ackAge>=0&&ackAge<=3.0;
    if(!valid)return english?@"The current Dock state is not verified.":
                              @"Chưa xác minh được trạng thái Dock của phiên hiện tại.";
    BOOL hidden=[ack[@"DockHidden"] boolValue];
    return english?(hidden?@"Dock is reported hidden.":@"Dock is reported visible."):
                   (hidden?@"Dock đang được báo cáo là ẩn.":@"Dock đang được báo cáo là hiện.");
 }
 if([text containsString:@"status"] || [text containsString:@"trạng thái"] ||
    [text containsString:@"carplay"]){
    NSDictionary *session=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist"];
    double age=NSDate.date.timeIntervalSince1970-[session[@"Timestamp"] doubleValue];
    BOOL active=[session[@"Active"] isEqual:@YES] && age>=0 && age<=2.5;
    return english?(active?@"DuoFace CarPlay is active.":@"No active DuoFace CarPlay session."):
      (active?@"DuoFace CarPlay đang hoạt động.":@"Chưa có phiên DuoFace CarPlay hoạt động.");
 }
 if([text containsString:@"map"] || [text containsString:@"bản đồ"]){
    return english?@"Open Maps directly on CarPlay. Native split remains experimental.":
      @"Hãy mở Maps trực tiếp trên CarPlay. Ghép bản đồ native vẫn đang thử nghiệm.";
 }
 return english?@"You can ask about CarPlay status, the Dock, or Maps. I do not start apps or change driving controls by voice.":
   @"Bạn có thể hỏi trạng thái CarPlay, Dock hoặc bản đồ. Trợ lý không tự mở ứng dụng hay đổi điều khiển lái xe.";
}
- (void)finishTranscript:(NSString *)transcript generation:(NSUInteger)generation {
 if(generation!=self.generation)return;
 void (^callback)(NSString *)=[self.done copy];
 NSString *reply=[self voiceReply:transcript];
 [self stop];
 if(callback)callback(reply);
 AVSpeechUtterance *u=[AVSpeechUtterance speechUtteranceWithString:reply];
 u.voice=[AVSpeechSynthesisVoice voiceWithLanguage:
            [DFCurrentExtended()[@"Language"] isEqual:@"en"]?@"en-US":@"vi-VN"];
 u.rate=.47;
 [self.speaker speakUtterance:u];
}
- (void)startWithPermission:(void (^)(NSString *))callback {
 if(self.listening)return;
 self.done=[callback copy];
 NSString *locale=[DFCurrentExtended()[@"Language"] isEqual:@"en"]?@"en-US":@"vi-VN";
 self.recognizer=[[SFSpeechRecognizer alloc]initWithLocale:
                       [NSLocale localeWithLocaleIdentifier:locale]];
 if(!self.recognizer.isAvailable){
    if(callback)callback(DFLocalize(@"Nhận dạng giọng nói hiện không khả dụng.",
                                      @"Speech recognition is unavailable."));
    return;
 }
 NSError *error=nil;
 AVAudioSession *session=[AVAudioSession sharedInstance];
 if(![session setCategory:AVAudioSessionCategoryPlayAndRecord
                   mode:AVAudioSessionModeDefault
                options:AVAudioSessionCategoryOptionMixWithOthers
                  error:&error] || ![session setActive:YES error:&error]) {
    if(callback)callback(error.localizedDescription?:@"Audio session unavailable");
    return;
 }
 self.ownsVoiceAudioSession=YES;
 AVAudioEngine *engine=[AVAudioEngine new];
 self.engine=engine;
 self.request=[SFSpeechAudioBufferRecognitionRequest new];
 self.request.shouldReportPartialResults=NO;
 AVAudioInputNode *input=engine.inputNode;
 AVAudioFormat *format=[input outputFormatForBus:0];
 if(!input || format.sampleRate<=0){
   [self stop];if(callback)callback(@"Input microphone unavailable");return;
 }
 NSUInteger generation=++self.generation;
 __weak typeof(self) weakSelf=self;
 [input installTapOnBus:0 bufferSize:1024 format:format
      block:^(AVAudioPCMBuffer *buffer,__unused AVAudioTime *when){
       DFVoiceAssistant *owner=weakSelf;
       [owner.request appendAudioPCMBuffer:buffer];
      }];
 [engine prepare];
 if(![engine startAndReturnError:&error]){
    [self stop];if(callback)callback(error.localizedDescription?:@"Microphone start failed");return;
 }
 self.listening=YES;
 self.task=[self.recognizer recognitionTaskWithRequest:self.request
    resultHandler:^(SFSpeechRecognitionResult *result,NSError *failure) {
      if(generation!=weakSelf.generation)return;
      if(result.isFinal && result.bestTranscription.formattedString.length){
         dispatch_async(dispatch_get_main_queue(),^{
           [weakSelf finishTranscript:result.bestTranscription.formattedString generation:generation];
         });
      }else if(failure){
         dispatch_async(dispatch_get_main_queue(),^{
           void (^done)(NSString *)=[weakSelf.done copy];
           [weakSelf stop];
           if(done)done(failure.localizedDescription?:@"Speech request failed");
         });
      }
    }];
 // Explicit single-command session bound to 12 seconds maximum.
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(12*NSEC_PER_SEC)),
                dispatch_get_main_queue(),^{
   DFVoiceAssistant *owner=weakSelf;
   if(!owner || generation!=owner.generation || !owner.listening)return;
   void (^done)(NSString *)=[owner.done copy];
   [owner stop];
   if(done)done(DFLocalize(@"Không nghe được lệnh. Chạm mic để thử lại.",
                            @"No command recognized. Tap microphone to retry."));
 });
}
- (void)toggleFromController:(UIViewController *)controller
                  completed:(void (^)(NSString *))completion {
 (void)controller;
 if(self.listening){[self stop];if(completion)completion(
         DFLocalize(@"Đã dừng nghe.",@"Listening stopped."));return;}
 __weak typeof(self) weakSelf=self;
 [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status){
    dispatch_async(dispatch_get_main_queue(),^{
      if(!weakSelf)return;
      if(status!=SFSpeechRecognizerAuthorizationStatusAuthorized){
         if(completion)completion(DFLocalize(@"Chưa cấp quyền nhận dạng giọng nói.",
                                      @"Speech recognition is not authorized."));return;
      }
      [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
         dispatch_async(dispatch_get_main_queue(),^{
            if(!weakSelf)return;
            if(!granted){
              if(completion)completion(DFLocalize(@"Chưa cấp quyền micro.",
                                       @"Microphone access is not authorized."));
              return;
            }
            [weakSelf startWithPermission:completion];
         });
      }];
    });
 }];
}
- (void)dealloc {[self stop];}
@end
