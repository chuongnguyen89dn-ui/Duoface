// Independent shared selected-app catalog for native12-style CarPlay picker.
// The system Home publisher MUST consume this exact *installed AND enabled*
// set once a real iOS16 Dashboard roster/launch ABI is verified. This file
// does NOT claim or spoof a native CarPlay Home application registration.
#ifndef DF_CARPLAY_SELECTED_APP_CATALOG_H
#define DF_CARPLAY_SELECTED_APP_CATALOG_H
#import <Foundation/Foundation.h>
#import "DFEnabledAppsPolicy.h"
NS_INLINE NSArray<NSString *> *DFCarPlaySelectedInstalledBundleIDs(
                   NSArray<NSString *> *installed, NSArray<NSString *> *enabled) {
  if(![installed isKindOfClass:NSArray.class] ||
     ![enabled isKindOfClass:NSArray.class])return @[];
  NSSet<NSString *> *allowed=[NSSet setWithArray:enabled];
  NSMutableOrderedSet<NSString *> *selected=[NSMutableOrderedSet new];
  for(id app in installed){
    if(![app isKindOfClass:NSString.class] ||
       !DFPickerAllowsApp(app,enabled) ||
       ![allowed containsObject:app])continue;
    [selected addObject:app];
  }
  return selected.array;
}
#endif
