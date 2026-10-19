#import <Foundation/Foundation.h>

// v1a diagnostic ONLY. Must never create a CarPlay window or start a hosted app.
@interface MTPreflight : NSObject
+ (void)startReadOnlyDiagnostics;
@end
