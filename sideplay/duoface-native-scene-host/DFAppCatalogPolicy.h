// Independent DuoFace app inventory; no proprietary vendor code.
#ifndef DF_APP_CATALOG_POLICY_H
#define DF_APP_CATALOG_POLICY_H
#import <Foundation/Foundation.h>
#import "DFAppEligibility.h"
NS_INLINE id DFAppProxyValue(id proxy,NSString *key) {
 if(!proxy||!key.length)return nil;
 @try{return [proxy valueForKey:key];}@catch(NSException *e){(void)e;return nil;}
}
NS_INLINE BOOL DFAppProxyBool(id obj) {
 return [obj respondsToSelector:@selector(boolValue)]&&[obj boolValue];
}
NS_INLINE NSDictionary<NSString *,NSString *> *DFCatalogRecordForProxy(id proxy) {
 id bundle=DFAppProxyValue(proxy,@"applicationIdentifier");
 if(!DFIsEligibleAppID(bundle))return nil;
 if(DFAppProxyBool(DFAppProxyValue(proxy,@"isPlaceholder"))||
    DFAppProxyBool(DFAppProxyValue(proxy,@"isLaunchProhibited")))return nil;
 id tags=DFAppProxyValue(proxy,@"appTags");
 if([tags isKindOfClass:NSArray.class]&&[tags containsObject:@"hidden"])return nil;
 id appType=DFAppProxyValue(proxy,@"applicationType");
 if([appType isKindOfClass:NSString.class]&&
    ![@[@"System",@"User"] containsObject:appType])return nil;
 id label=DFAppProxyValue(proxy,@"localizedName");
 NSString *name=[label isKindOfClass:NSString.class]&&[label length]?label:bundle;
 return @{@"bundle":bundle,@"name":name,
          @"kind":[appType isEqual:@"System"]?@"system":@"user"};
}
NS_INLINE NSArray<NSDictionary<NSString *,NSString *> *> *DFCatalogRecordsFromProxies(NSArray *proxies) {
 if(![proxies isKindOfClass:NSArray.class])return @[];
 NSMutableArray *result=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];
 for(id proxy in proxies){
  NSDictionary *item=DFCatalogRecordForProxy(proxy);
  if(!item||[seen containsObject:item[@"bundle"]])continue;
  [seen addObject:item[@"bundle"]];[result addObject:item];
 }
 [result sortUsingComparator:^NSComparisonResult(NSDictionary *x,NSDictionary *y){
  return [x[@"name"] localizedCaseInsensitiveCompare:y[@"name"]];
 }];
 return result;
}
#endif
