#pragma once
#import <Foundation/Foundation.h>
// Installed-app discovery for a MANUAL, source-coherent GOFA-style DuoFace bubble.
// A source is selectable ONLY if the actual app is installed on the device.
// This does not assert a publisher exists or that speed/limit samples are live.
// Exact numeric publisher remains an independent requirement.
FOUNDATION_EXPORT NSString *DFSpeedBundleForSource(NSInteger source);
FOUNDATION_EXPORT NSString *DFSpeedNameForSource(NSInteger source);
FOUNDATION_EXPORT BOOL DFSpeedSourceInstalled(NSInteger source);
FOUNDATION_EXPORT NSArray<NSNumber *> *DFSpeedInstalledSupportedSources(void);
