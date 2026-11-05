"""Normalize only the reviewed native-owner early rejection for frozen host tests.

Both exact bytes and insertion locations are mandatory. No changed geometry,
lifecycle code, or broader pattern is excluded from the original fingerprints.
"""

LEASE_IMPORT = b'#import "DFNativeMapLeasePolicy.h"\n'
LEASE_GUARD = '''    if (DFNativeMapOwnsBundleNow(bundleID)) {
        DFSceneLog(@"native-map-phone-host-refused",bundleID,@"fresh same-session native owner lease");
        if (error) *error=DFSceneError(117,@"Ứng dụng đang nằm trong ô bản đồ CarPlay");
        return nil;
    }
'''.encode("utf-8")
IMPORT_CONTEXT = (
    b'#import "DFHostedMapRenderSize.h"\n'
    + LEASE_IMPORT
    + b'#import "DFYouTubeHostState.h"\n'
)
GUARD_CONTEXT = '''    if (![bundleID isKindOfClass:NSString.class] || bundleID.length==0) {
        if (error) *error=DFSceneError(102,@"bundleID không hợp lệ");
        return nil;
    }
'''.encode("utf-8") + LEASE_GUARD + b'    if (self.live[bundleID]) {\n'


def without_native_map_guard(content: bytes) -> bytes:
    for exact in (LEASE_IMPORT, LEASE_GUARD, IMPORT_CONTEXT, GUARD_CONTEXT):
        if content.count(exact) != 1:
            raise AssertionError("Native map guard/import must match the exact reviewed insertion")
    return content.replace(LEASE_IMPORT, b"", 1).replace(LEASE_GUARD, b"", 1)
