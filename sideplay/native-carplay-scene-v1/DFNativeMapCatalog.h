// Read only the actual FBS application library already owned by CarPlay.
// A declaration is not a launch/keepalive contract. The catalogue remains
// scoped to the three map apps accepted by the existing scene adapter.
#ifndef DF_NATIVE_MAP_CATALOG_H
#define DF_NATIVE_MAP_CATALOG_H
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "../duoface-native-scene-host/DFNativeMapLeasePolicy.h"

NS_INLINE id DFNativeMapCatalogObject(id source,NSString *name) {
 if(!source)return nil;
 SEL selector=NSSelectorFromString(name);
 Method method=class_getInstanceMethod(object_getClass(source),selector);
 char result[8]={0};
 if(!method || method_getNumberOfArguments(method)!=2)return nil;
 method_getReturnType(method,result,sizeof(result));
 if(result[0]!='@')return nil;
 @try{return ((id(*)(id,SEL))objc_msgSend)(source,selector);}
 @catch(__unused NSException *exception){return nil;}
}
NS_INLINE id DFNativeMapExistingLibrary(id source) {
 if(!source)return nil;
 Class library=NSClassFromString(@"FBSApplicationLibrary");
 if(!library)return nil;
 if([source isKindOfClass:library])return source;
 for(NSString *name in @[@"applicationLibrary",@"_applicationLibrary",
                          @"appLibrary",@"_appLibrary"]) {
   id value=DFNativeMapCatalogObject(source,name);
   if([value isKindOfClass:library])return value;
 }
 // Same read-only, object-typed library lookup as the verified Home
 // publisher. Never invoke a factory or allocate a replacement FBS library.
 for(Class cursor=object_getClass(source);cursor;cursor=class_getSuperclass(cursor)) {
   unsigned int count=0;
   Ivar *ivars=class_copyIvarList(cursor,&count);
   for(unsigned int index=0;index<count;index++) {
     const char *type=ivar_getTypeEncoding(ivars[index]);
     const char *name=ivar_getName(ivars[index]);
     if(!type || type[0]!='@' || type[1]=='?' || !name)continue;
     NSString *key=[NSString stringWithUTF8String:name];
     if(![key.lowercaseString containsString:@"library"])continue;
     @try {
       id value=object_getIvar(source,ivars[index]);
       if([value isKindOfClass:library]){free(ivars);return value;}
     } @catch(__unused NSException *exception) {}
   }
   free(ivars);
 }
 return nil;
}
NS_INLINE NSArray<NSString *> *DFNativeMapCatalogFromLibrary(id library) {
 Class expected=NSClassFromString(@"FBSApplicationLibrary");
 if(!expected || ![library isKindOfClass:expected])return nil;
 // The factory's result is an FBSApplicationLibrary, NOT an NSArray/NSSet.
 id applications=DFNativeMapCatalogObject(library,@"allInstalledApplications");
 if(![applications isKindOfClass:NSArray.class])return nil;
 NSMutableSet<NSString *> *bundles=[NSMutableSet new];
 for(id info in applications) {
   id bundle=DFNativeMapCatalogObject(info,@"bundleIdentifier");
   id declaration=DFNativeMapCatalogObject(info,@"carPlayDeclaration");
   if(!DFNativeMapAllowedBundle(bundle) || !declaration)continue;
   id declared=DFNativeMapCatalogObject(declaration,@"bundleIdentifier");
   if(![declared isKindOfClass:NSString.class] || ![declared isEqual:bundle])continue;
   [bundles addObject:bundle];
 }
 return [[bundles allObjects] sortedArrayUsingSelector:@selector(compare:)];
}
#endif
