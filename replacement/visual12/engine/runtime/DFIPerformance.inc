// Opt-in baseline recorder. CPU/memory are SpringBoard process-wide, not Split-only.
static dispatch_queue_t DFIPerfQueue;
static NSTimer *DFIPerfTimer;
static NSMutableDictionary<NSString *,NSNumber *> *DFIPerfCounters;
static task_thread_times_info_data_t DFIPerfLastCPU;
static CFTimeInterval DFIPerfLastWall;
static NSString *const DFIPerfPath=@"/var/mobile/Library/Logs/DuoFaceVisual12-performance.jsonl";
static void DFIPerfWrite(NSDictionary *row) {
    if(!DFIPerfQueue)return;
    NSMutableDictionary *record=[row mutableCopy];
    record[@"timestamp"]=[NSDate date].description;
    record[@"schema"]=@1;
    dispatch_async(DFIPerfQueue,^{
        @autoreleasepool {
            NSError *error=nil;
            NSData *data=[NSJSONSerialization dataWithJSONObject:record options:0 error:&error];
            if(!data)return;
            NSMutableData *line=[data mutableCopy];[line appendBytes:"\n" length:1];
            NSFileManager *fm=NSFileManager.defaultManager;
            NSString *dir=[DFIPerfPath stringByDeletingLastPathComponent];
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
            if([[fm attributesOfItemAtPath:DFIPerfPath error:nil] fileSize] > 4*1024*1024) {
                NSString *previous=[DFIPerfPath stringByAppendingString:@".previous"];
                [fm removeItemAtPath:previous error:nil];
                [fm moveItemAtPath:DFIPerfPath toPath:previous error:nil];
            }
            if(![fm fileExistsAtPath:DFIPerfPath])[fm createFileAtPath:DFIPerfPath contents:nil attributes:@{NSFilePosixPermissions:@0644}];
            NSFileHandle *file=[NSFileHandle fileHandleForWritingAtPath:DFIPerfPath];
            [file seekToEndOfFile];[file writeData:line];[file closeFile];
        }
    });
}
static void DFIPerfCount(NSString *key) {
    if(!DFIPerfTimer)return;
    DFIPerfCounters[key]=@([DFIPerfCounters[key] unsignedLongLongValue]+1);
}
static void DFIPerfMark(NSString *event,NSDictionary *extra) {
    if(!DFIPerfTimer)return;
    NSMutableDictionary *row=[@{@"type":@"event",@"name":event} mutableCopy];
    if(extra)[row addEntriesFromDictionary:extra];
    DFIPerfWrite(row);
}
static void DFIPerfSample(void) {
    if(!DFIPerfTimer)return;
    task_thread_times_info_data_t cpu={0};
    mach_msg_type_number_t count=TASK_THREAD_TIMES_INFO_COUNT;
    kern_return_t status=task_info(mach_task_self(),TASK_THREAD_TIMES_INFO,(task_info_t)&cpu,&count);
    mach_task_basic_info_data_t memory={0};
    count=MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t memStatus=task_info(mach_task_self(),MACH_TASK_BASIC_INFO,(task_info_t)&memory,&count);
    CFTimeInterval now=CACurrentMediaTime();
    NSMutableDictionary *row=[@{@"type":@"sample",@"thermal_state":@(NSProcessInfo.processInfo.thermalState),
        @"layout_passes":DFIPerfCounters[@"layout_passes"]?:@0,
        @"resize_applied":DFIPerfCounters[@"resize_applied"]?:@0,
        @"resize_skipped":DFIPerfCounters[@"resize_skipped"]?:@0,
        @"scene_updates":DFIPerfCounters[@"scene_updates"]?:@0} mutableCopy];
    if(status==KERN_SUCCESS) {
        double seconds=(cpu.user_time.seconds-DFIPerfLastCPU.user_time.seconds)+(cpu.user_time.microseconds-DFIPerfLastCPU.user_time.microseconds)/1e6+
           (cpu.system_time.seconds-DFIPerfLastCPU.system_time.seconds)+(cpu.system_time.microseconds-DFIPerfLastCPU.system_time.microseconds)/1e6;
        if(DFIPerfLastWall>0&&now>DFIPerfLastWall)row[@"springboard_cpu_percent"]=@(MAX(0,100*seconds/(now-DFIPerfLastWall)));
        DFIPerfLastCPU=cpu;DFIPerfLastWall=now;
    } else row[@"cpu_error"]=@(status);
    if(memStatus==KERN_SUCCESS)row[@"springboard_resident_bytes"]=@(memory.resident_size);
    else row[@"memory_error"]=@(memStatus);
    DFIPerfWrite(row);
}
static void DFIPerfStop(void) {
    if(!DFIPerfTimer)return;
    DFIPerfMark(@"recording_stop",nil);
    [DFIPerfTimer invalidate];DFIPerfTimer=nil;
}
static void DFIPerfStart(void) {
    if(DFIPerfTimer||![DFIPref(@"perfEnabled") boolValue])return;
    static dispatch_once_t once;
    dispatch_once(&once,^{DFIPerfQueue=dispatch_queue_create("com.duoface.visual12.performance",DISPATCH_QUEUE_SERIAL);});
    DFIPerfCounters=[NSMutableDictionary dictionary];
    DFIPerfLastCPU=(task_thread_times_info_data_t){0};DFIPerfLastWall=0;
    DFIPerfTimer=[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer){DFIPerfSample();}];
    DFIPerfMark(@"recording_start",@{@"scope":@"SpringBoard process-wide; not Split-only",@"ios":UIDevice.currentDevice.systemVersion});
}
