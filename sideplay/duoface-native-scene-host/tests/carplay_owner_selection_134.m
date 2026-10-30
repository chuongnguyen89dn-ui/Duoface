#import <Foundation/Foundation.h>
#import "../DFCarPlayOwnerSelection.h"
#include <assert.h>
#include <stdio.h>
static NSDictionary *scene(NSString *bundle,NSString *sceneID,id controller) {
    return @{@"Bundle":bundle,@"SceneID":sceneID,@"Controller":controller};
}
int main(void) {@autoreleasepool {
    NSObject *one=[NSObject new],*two=[NSObject new],*other=[NSObject new];
    NSDictionary *duoface=scene(@"com.duoface.native.scenehost",@"native-own-1",one);
    NSDictionary *gofa=scene(@"com.lumi.GOFA",@"native-gofa",other);
    NSDictionary *youtube=scene(@"com.google.ios.youtube",@"native-yt",other);
    NSDictionary *second=scene(@"com.duoface.native.scenehost",@"native-own-2",two);
    int checks=0;
#define CHECK(expr) do {assert((expr)); checks++;} while(0)
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[])==nil);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[gofa])==nil);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[duoface])==duoface);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[duoface,gofa])==duoface);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[gofa,duoface])==duoface);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[gofa,duoface,youtube])==duoface);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[duoface,gofa,youtube])==duoface);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[duoface,second])==nil);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[second,gofa,duoface])==nil);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[@"junk",gofa,duoface])==duoface);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[@{@"Bundle":@"com.duoface.native.scenehost",
          @"SceneID":@"", @"Controller":one}])==nil);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[@{@"Bundle":@"com.duoface.native.scenehost",
          @"SceneID":@"scene"}])==nil);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[duoface,
          @{@"Bundle":@"com.duoface.native.scenehost",@"SceneID":@"", @"Controller":two}])==nil);
    CHECK(DFOwnerUniqueDuoFaceCandidate(@[gofa,youtube])==nil);
    printf("QA134_UNIQUE_DUOFACE_WITH_UNRELATED_CARPLAY_SCENES_PASS count=%d\\n",checks);
#undef CHECK
    return 0;
}}
