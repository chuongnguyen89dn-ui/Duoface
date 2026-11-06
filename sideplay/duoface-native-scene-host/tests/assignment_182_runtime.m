#import <Foundation/Foundation.h>
#import "../DF182NativeMapAssignment.h"
#import "../DF182BlockCompletionABI.h"
#define CHECK(x) do{if(!(x)){fprintf(stderr,"FAILED line %d: %s\n",__LINE__,#x);return 1;}}while(0)
int main(void){@autoreleasepool{
 NSString *dir=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
 CHECK([NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil]);
 NSString *choice=[dir stringByAppendingPathComponent:@"choice.plist"];
 NSString *pulse=[dir stringByAppendingPathComponent:@"pulse.plist"];
 NSString *session=NSUUID.UUID.UUIDString;
 NSMutableDictionary *a=[@{@"Version":@2,@"AssignmentID":NSUUID.UUID.UUIDString,
  @"Session":session,@"BundleID":@"com.google.Maps",@"PhysicalSlot":@1,@"Slot":@0,@"AssignedAt":@995} mutableCopy];
 NSMutableDictionary *p=[@{@"Session":session,@"Active":@YES,@"Timestamp":@999} mutableCopy];
 CHECK([a writeToFile:choice atomically:YES]);CHECK([p writeToFile:pulse atomically:YES]);
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)!=nil);
 p[@"Session"]=NSUUID.UUID.UUIDString;[p writeToFile:pulse atomically:YES];
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)==nil); // prior session never reused
 p[@"Session"]=session;p[@"Active"]=@NO;[p writeToFile:pulse atomically:YES];
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)==nil);
 p[@"Active"]=@YES;p[@"Timestamp"]=@990;[p writeToFile:pulse atomically:YES];
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)==nil); // heartbeat expired
 p[@"Timestamp"]=@1001;[p writeToFile:pulse atomically:YES];
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)==nil); // future pulse
 p[@"Timestamp"]=@999;[p writeToFile:pulse atomically:YES];
 a[@"BundleID"]=@"com.waze.iphone";[a writeToFile:choice atomically:YES];
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)==nil);
 a[@"BundleID"]=@"com.google.Maps";a[@"PhysicalSlot"]=@2;[a writeToFile:choice atomically:YES];
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)==nil);
 [@{@"Version":@1,@"Slot":@1} writeToFile:choice atomically:YES];
 CHECK(DF182AssignmentAtPaths(choice,pulse,1000)==nil); // legacy choice is not assignment
 __block int calls=0;void(^valid)(void)=^{calls++;};
 CHECK(DF182VoidCompletion(valid));CHECK(DF182VoidCompletion(nil));
 void(^wrongArgument)(BOOL)=^(__unused BOOL value){};
 int(^wrongReturn)(void)=^{return 1;};
 CHECK(!DF182VoidCompletion(wrongArgument));CHECK(!DF182VoidCompletion(wrongReturn));
 valid();CHECK(calls==1);
 CHECK([NSFileManager.defaultManager removeItemAtPath:dir error:nil]);
 puts("QA182_ASSIGNMENT_LIFETIME_AND_COMPLETION_ABI_RUNTIME_PASS");
 return 0;
}}
