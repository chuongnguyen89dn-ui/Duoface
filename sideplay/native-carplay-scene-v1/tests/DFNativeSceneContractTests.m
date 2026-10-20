#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
#import "../DFNativeSceneContract.h"
static void Assert(BOOL condition,NSString *reason) {
  if(!condition) {
     NSLog(@"NATIVE_SCENE_CONTRACT_FAIL: %@",reason);
     exit(1);
  }
}
static BOOL Near(CGFloat a,CGFloat b){return fabs(a-b)<0.01;}
int main(int argc,char **argv){
 @autoreleasepool {
  (void)argc;(void)argv;
  CGRect full=CGRectMake(0,0,507.333333,240),usable=CGRectNull;
  Assert(DFNativeSceneUsable(full,0,45,0,0,&usable),@"left bar native usable");
  Assert(Near(usable.origin.x,45) && Near(usable.size.width,462.333333),@"real device geometry");
  CGRect bottom=CGRectNull;
  Assert(DFNativeSceneUsable(full,0,0,60,0,&bottom) && Near(bottom.size.height,180),@"bottom native bar");
  Assert(!DFNativeSceneUsable(full,0,600,0,0,NULL),@"overlapping insets");
  Assert(!DFNativeSceneUsable(full,-1,0,0,0,NULL),@"negative insets");
  Assert(!DFNativeSceneUsable(full,NAN,0,0,0,NULL),@"nan insets");
  CGRect left=CGRectNull,right=CGRectNull;
  Assert(DFNativeSceneSplit(usable,0.5,12,&left,&right),@"two pane split");
  Assert(Near(left.size.width,right.size.width),@"split symmetric");
  Assert(Near(CGRectGetMaxX(right),CGRectGetMaxX(usable)),@"right edge");
  Assert(DFNativeSceneSplit(usable,0.73,12,&left,&right) && left.size.width>right.size.width,@"drag ratio");
  Assert(!DFNativeSceneSplit(usable,-1,12,NULL,NULL),@"bad ratio");
  Assert(!DFNativeSceneSplit(usable,0.5,50,NULL,NULL),@"bad divider");
  NSString *session=NSUUID.UUID.UUIDString;
  NSTimeInterval now=NSDate.date.timeIntervalSince1970;
  NSDictionary *record=DFNativeSceneOwnerRecord(session,full,usable,YES,now);
  Assert(record!=nil,@"create owner");
  Assert(DFNativeSceneValidateOwnerRecord(record,session,now),@"fresh owner");
  Assert(DFNativeSceneValidateOwnerRecord(record,session,now+2.5),@"lease still fresh");
  Assert(!DFNativeSceneValidateOwnerRecord(record,session,now+3.1),@"lease expired");
  Assert(!DFNativeSceneValidateOwnerRecord(record,NSUUID.UUID.UUIDString,now),@"session mismatch");
  NSMutableDictionary *changed=[record mutableCopy]; changed[@"FullW"]=@120;
  Assert(!DFNativeSceneValidateOwnerRecord(changed,session,now),@"forged geometry");
  changed=[record mutableCopy];changed[@"UsableX"]=@(INFINITY);
  Assert(!DFNativeSceneValidateOwnerRecord(changed,session,now),@"nonfinite geometry");
  changed=[record mutableCopy];changed[@"Version"]=@3;
  Assert(!DFNativeSceneValidateOwnerRecord(changed,session,now),@"bad version");
  Assert(DFNativeSceneOwnerRecord(@"invalid",full,usable,YES,now)==nil,@"bad session");
  NSLog(@"NATIVE_SCENE_CONTRACT_TESTS_PASS geometry=507.333x240 native=45px split/session/expiry");
 }
 return 0;
}
