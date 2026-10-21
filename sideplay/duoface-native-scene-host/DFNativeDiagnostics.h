#import <Foundation/Foundation.h>

// On-device, user-initiated diagnostic export. NEVER uploads data itself.
// Used to obtain the SpringBoard/CarPlay .ips evidence required to diagnose
// the observed video Safe Mode failure without NewTerm/Filza commands.
@interface DFNativeDiagnostics : NSObject
+ (NSArray<NSURL *> *)prepareShareFiles;
@end
