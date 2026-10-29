// DuoFace independent in-car App picker display preferences, iOS16 rootless.
// Only layout/UI of the picker. Does NOT resize remote app scenes or system Dock.
#ifndef DF_APP_PICKER_DISPLAY_POLICY_H
#define DF_APP_PICKER_DISPLAY_POLICY_H
#import <Foundation/Foundation.h>
#import <notify.h>
static NSString *const DFPickerDisplayPath =
 @"/var/mobile/Library/Preferences/com.duoface.nativehost.picker-display.v1.plist";
static const char *const DFPickerDisplayChanged =
 "com.duoface.nativehost.picker-display.changed.v1";
NS_INLINE NSDictionary *DFDefaultPickerDisplay(void) {
 return @{@"GridColumns":@4, @"GridRows":@2, @"ShowAppNames":@YES};
}
NS_INLINE NSDictionary *DFReadPickerDisplayAtPath(NSString *path) {
 NSDictionary *record=[NSDictionary dictionaryWithContentsOfFile:path];
 if(![record isKindOfClass:NSDictionary.class] || ![record[@"Version"] isEqual:@1] ||
    ![record[@"GridColumns"] isKindOfClass:NSNumber.class] ||
    ![record[@"GridRows"] isKindOfClass:NSNumber.class] ||
    ![record[@"ShowAppNames"] isKindOfClass:NSNumber.class])return DFDefaultPickerDisplay();
 NSInteger columns=[record[@"GridColumns"] integerValue];
 NSInteger rows=[record[@"GridRows"] integerValue];
 if(columns<4 || columns>6 || rows<2 || rows>3)return DFDefaultPickerDisplay();
 return @{@"GridColumns":@(columns),@"GridRows":@(rows),
          @"ShowAppNames":@([record[@"ShowAppNames"] boolValue])};
}
NS_INLINE NSDictionary *DFCurrentPickerDisplay(void) {
 return DFReadPickerDisplayAtPath(DFPickerDisplayPath);
}
NS_INLINE BOOL DFWritePickerDisplayAtPath(NSInteger columns,NSInteger rows,
                                         BOOL showNames,NSString *path) {
 if(columns<4 || columns>6 || rows<2 || rows>3 ||
    ![path isKindOfClass:NSString.class] || !path.length)return NO;
 NSDictionary *data=@{@"Version":@1,@"GridColumns":@(columns),
                       @"GridRows":@(rows),@"ShowAppNames":@(showNames)};
 if(![data writeToFile:path atomically:YES])return NO;
 NSDictionary *readback=DFReadPickerDisplayAtPath(path);
 return [readback[@"GridColumns"] integerValue]==columns &&
        [readback[@"GridRows"] integerValue]==rows &&
        [readback[@"ShowAppNames"] boolValue]==showNames;
}
NS_INLINE BOOL DFSavePickerDisplay(NSInteger columns,NSInteger rows,BOOL showNames) {
 if(!DFWritePickerDisplayAtPath(columns,rows,showNames,DFPickerDisplayPath))return NO;
 notify_post(DFPickerDisplayChanged);
 return YES;
}
// Only the app listing uses customizable columns; running-app controls stay 4x1.
NS_INLINE NSInteger DFPickerCapacity(NSInteger columns,NSInteger rows) {
 return MAX(4,MIN(6,columns))*MAX(2,MIN(3,rows));
}
#endif
