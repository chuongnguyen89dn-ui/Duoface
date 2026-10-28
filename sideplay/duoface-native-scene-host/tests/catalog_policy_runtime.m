#import <Foundation/Foundation.h>
#import "DFAppCatalogPolicy.h"
static void check(BOOL pass,NSString *msg) {if(!pass){NSLog(@"CATALOG_FAIL %@",msg);abort();}}
int main(void){@autoreleasepool {
 NSDictionary *youtube=@{@"applicationIdentifier":@"com.google.ios.youtube",
   @"localizedName":@"YouTube",@"applicationType":@"User"};
 NSDictionary *maps=@{@"applicationIdentifier":@"com.apple.Maps",
   @"localizedName":@"Maps",@"applicationType":@"System"};
 NSDictionary *hidden=@{@"applicationIdentifier":@"com.example.hidden",
   @"appTags":@[@"hidden"],@"applicationType":@"User"};
 NSDictionary *placeholder=@{@"applicationIdentifier":@"com.example.placeholder",
   @"isPlaceholder":@YES};
 NSDictionary *blocked=@{@"applicationIdentifier":@"com.example.prohibited",
   @"isLaunchProhibited":@YES};
 NSDictionary *service=@{@"applicationIdentifier":@"com.apple.springboard"};
 NSArray *items=DFCatalogRecordsFromProxies(@[youtube,youtube,maps,hidden,placeholder,blocked,service]);
 check(items.count==2,@"only valid unique user-facing apps");
 check([items[0][@"bundle"] isEqual:@"com.apple.Maps"],@"sort by displayed name");
 check([items[0][@"kind"] isEqual:@"system"],@"system class retained");
 check([items[1][@"kind"] isEqual:@"user"],@"user class retained");
 check(DFCatalogRecordsFromProxies(@[]).count==0,@"empty");
 NSLog(@"DUOFACE_CATALOG_RUNTIME_PASS");
 }return 0;}
