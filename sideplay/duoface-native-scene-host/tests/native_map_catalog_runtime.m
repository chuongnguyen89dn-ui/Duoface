// Executes the actual catalogue helper against a controlled FBS-shaped library.
// Verifies enumeration/data validation, not a live private OS ABI or map pixels.
#import <Foundation/Foundation.h>
#include <assert.h>
#import "../../native-carplay-scene-v1/DFNativeMapCatalog.h"

@interface FBSApplicationLibrary : NSObject
@property(nonatomic,strong) id applications;
- (id)allInstalledApplications;
@end
@implementation FBSApplicationLibrary
- (id)allInstalledApplications {return self.applications;}
@end
@interface MapCatalogInfo : NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@property(nonatomic,strong) id carPlayDeclaration;
@end
@implementation MapCatalogInfo
@end
@interface MapCatalogBadGetter : NSObject
- (NSInteger)bundleIdentifier;
@end
@implementation MapCatalogBadGetter
- (NSInteger)bundleIdentifier {assert(0 && "wrong ABI getter must never run");return 0;}
@end
@interface MapCatalogHolder : NSObject {
@public id _nativeLibrary;
}
@end
@implementation MapCatalogHolder
@end
@interface MapCatalogGetter : NSObject
@property(nonatomic,strong) id applicationLibrary;
@end
@implementation MapCatalogGetter
@end
static MapCatalogInfo *info(NSString *bundle,NSString *declared) {
    MapCatalogInfo *value=[MapCatalogInfo new];
    value.bundleIdentifier=bundle;
    if(declared) {
        MapCatalogInfo *declaration=[MapCatalogInfo new];
        declaration.bundleIdentifier=declared;
        value.carPlayDeclaration=declaration;
    }
    return value;
}
int main(void) {
 @autoreleasepool {
    FBSApplicationLibrary *library=[FBSApplicationLibrary new];
    library.applications=@[
        info(@"com.waze.iphone",@"com.waze.iphone"),
        info(@"com.google.Maps",@"com.google.Maps"),
        info(@"com.google.Maps",@"com.google.Maps"),
        info(@"com.apple.Maps",nil),
        info(@"com.apple.Maps",@"com.google.Maps"),
        info(@"com.google.youtube",@"com.google.youtube"),
        info(@"com.example.audio",@"com.example.audio"),
        NSNull.null,[MapCatalogBadGetter new]];
    NSArray *expected=@[@"com.google.Maps",@"com.waze.iphone"];
    assert([DFNativeMapCatalogFromLibrary(library) isEqual:expected]);
    assert(DFNativeMapCatalogFromLibrary(library.applications)==nil);
    assert(DFNativeMapCatalogFromLibrary(nil)==nil);
    MapCatalogGetter *getter=[MapCatalogGetter new];
    getter.applicationLibrary=library;
    assert(DFNativeMapExistingLibrary(getter)==library);
    MapCatalogHolder *holder=[MapCatalogHolder new];
    holder->_nativeLibrary=library;
    assert(DFNativeMapExistingLibrary(holder)==library);
    assert(DFNativeMapExistingLibrary(library)==library);
    assert(DFNativeMapExistingLibrary(NSNull.null)==nil);
    library.applications=[NSSet setWithObject:info(@"com.google.Maps",@"com.google.Maps")];
    assert(DFNativeMapCatalogFromLibrary(library)==nil);
    library.applications=@[];
    assert([DFNativeMapCatalogFromLibrary(library) isEqual:@[]]);
    puts("PASS_NATIVE_MAP_REAL_LIBRARY_ENUMERATION_EXACT_DECLARATIONS_SUPPORTED_SCOPE");
 }
 return 0;
}
