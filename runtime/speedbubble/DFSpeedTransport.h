#pragma once
#import <Foundation/Foundation.h>
// Versioned DuoFace-owned IPC between separately injected app source and
// DuoFace's SpringBoard CarPlay UIWindow. No GOFAHUD/GMapHUD runtime dependency.
// ALL LIMITS IN km/h. A missing speed limit must remain unknown, never 0.
typedef NS_ENUM(NSInteger, DFSpeedAppSource) {
  DFSpeedAppSourceNone=0, DFSpeedAppSourceGoogleMaps=1,
  DFSpeedAppSourceWaze=2, DFSpeedAppSourceVietMap=3,
  DFSpeedAppSourceGOFA=4
};
typedef struct {
  DFSpeedAppSource source;
  NSInteger currentKmh;
  NSInteger limitKmh;
  BOOL hasCurrent;
  BOOL hasLimit;
  NSTimeInterval ageSeconds;
} DFSpeedHUDRecord;
FOUNDATION_EXPORT BOOL DFSpeedHUDPublish(DFSpeedAppSource source,
  NSInteger currentKmh, BOOL hasCurrent, NSInteger limitKmh, BOOL hasLimit);
FOUNDATION_EXPORT BOOL DFSpeedHUDReadBest(DFSpeedHUDRecord *record);
