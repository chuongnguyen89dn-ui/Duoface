// DuoFace first-party adapter for an actual Apple CarPlay maneuver.
// A native navigation owner must pass the real CPManeuver and its current
// CPTravelEstimates. This file does NOT intercept or invoke GOFA private APIs.
#import <Foundation/Foundation.h>
#import <CarPlay/CarPlay.h>
#import <math.h>
#import "DF168NativeManeuver.h"

BOOL DF168PublishNativeCarPlayManeuver(CPManeuver *maneuver,CPTravelEstimates *estimate) {
  if(![maneuver isKindOfClass:CPManeuver.class] ||
     ![estimate isKindOfClass:CPTravelEstimates.class])return NO;
  NSString *text=nil;
  for(id item in maneuver.instructionVariants) {
    if([item isKindOfClass:NSString.class] && [item length]>0 && [item length]<180){
      text=[[item stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
             locale:[NSLocale localeWithLocaleIdentifier:@"vi_VN"]] lowercaseString];
      break;
    }
  }
  if(!text)return NO;
  BOOL left=([text containsString:@"re trai"] ||
             [text containsString:@"turn left"]);
  BOOL right=([text containsString:@"re phai"] ||
              [text containsString:@"turn right"]);
  BOOL uturn=([text containsString:@"quay dau"] ||
              [text containsString:@"u-turn"]);
  DF168Turn turn=DF168TurnUnknown;
  if(uturn&&!left&&!right)turn=DF168TurnUTurn;
  else if(left&&!right&&!uturn)turn=DF168TurnLeft;
  else if(right&&!left&&!uturn)turn=DF168TurnRight;
  if(turn==DF168TurnUnknown)return NO;
  NSMeasurement<NSUnitLength *> *distance=estimate.distanceRemaining;
  if(![distance isKindOfClass:NSMeasurement.class])return NO;
  double meters=[[distance measurementByConvertingToUnit:NSUnitLength.meters] doubleValue];
  if(!isfinite(meters) || meters<1 || meters>DF168_MAX_DISTANCE_METERS)return NO;
  return DF168PublishManeuver(turn,(NSUInteger)lround(meters));
}
