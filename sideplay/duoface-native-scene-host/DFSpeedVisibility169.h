#pragma once
#import <Foundation/Foundation.h>
// Own persistent, owner-independent Speed8 visibility decision.
// Absence of the preference means enabled (compatible with QA168).
FOUNDATION_EXPORT BOOL DF169SpeedBubbleEnabled(void);
FOUNDATION_EXPORT BOOL DF169SetSpeedBubbleEnabled(BOOL enabled);
FOUNDATION_EXPORT NSString *DF169SpeedBubbleChangeNotification(void);
