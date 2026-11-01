// Same explicit-selection scope as standalone Home launch. "Recommended"
// is only the third-party default; manually selected Safari is also supported.
#ifndef DF_SELECTED_HOME_ADMISSION_H
#define DF_SELECTED_HOME_ADMISSION_H
#import "DFEnabledAppsPolicy.h"
NS_INLINE BOOL DFSelectedHomeAdmission(NSString *bundle,NSArray *enabled) {
 return DFPickerAllowsApp(bundle,enabled) &&
    (DFIsRecommendedAppID(bundle) ||
     [bundle isEqualToString:@"com.apple.mobilesafari"]);
}
#endif
