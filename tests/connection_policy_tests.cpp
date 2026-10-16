// Linux C++17 deterministic tests: only the policy module; no device QA.
#include "../runtime/connection/DFConnectionPolicy.hpp"
#include <cassert>
#include <iostream>
#include <string>
#include <vector>
using namespace duoface::connection;
static const std::string yt="com.google.ios.youtube";
static const std::string map="com.google.Maps";
static bool installed(const std::string& s) { return s == yt || s == map; }
static bool own(const std::string& s) { return s == yt || s == map; }
static void testAutoOffDoesNothing() {
    Policy p;
    p.restoreLastAppFromExistingPreferences(yt);
    assert(p.onVerifiedConnected("",installed).empty());
    assert(p.onVerifiedConnected("",installed).empty());
    assert(!p.hasPendingClose());
}
static void testAutoOnRestoresOnceOnly() {
    Policy p; p.setAutoStart(true);
    p.restoreLastAppFromExistingPreferences(yt);
    auto a=p.onVerifiedConnected("",installed);
    assert(a.size()==1 && a[0].kind==ActionKind::LaunchApp && a[0].bundleId==yt);
    assert(p.onVerifiedConnected("",installed).empty());
    assert(p.onManagedAppActivated(yt).empty());
    p.onVerifiedDisconnected(100);
    auto b=p.onVerifiedConnected(yt,installed);
    assert(b.empty()); // already running on display, do not reload it
    assert(p.onVerifiedConnected(yt,installed).empty());
}
static void testRememberLastAppInSameSwitch() {
    Policy p; p.setAutoStart(true);
    assert(p.onVerifiedConnected("",installed).empty());
    auto a=p.onManagedAppActivated(map);
    assert(a.size()==1 && a[0].kind==ActionKind::SaveLastApp && a[0].bundleId==map);
    assert(p.onManagedAppActivated(map).empty());
    auto b=p.onManagedAppActivated(yt);
    assert(b.size()==1 && b[0].bundleId==yt);
    p.onVerifiedDisconnected(1);
    auto r=p.onVerifiedConnected("",installed);
    assert(r.size()==1 && r[0].kind==ActionKind::LaunchApp && r[0].bundleId==yt);
}
static void testDisableDuringReconnect() {
    Policy p; p.setAutoStart(true);
    p.restoreLastAppFromExistingPreferences(yt);
    p.setAutoStart(false);
    assert(p.onVerifiedConnected("",installed).empty());
}
static void testRejectUnknownApps() {
    Policy p; p.setAutoStart(true);
    for (auto s : {"", "bad", "com..bad", "com.bad;rm", ".com.bad", "com.bad.", "com.bad/"}) {
        assert(!Policy::validBundleId(s));
        p.restoreLastAppFromExistingPreferences(s);
        assert(p.lastApp().empty());
    }
    assert(p.onVerifiedConnected("",installed).empty());
    p.onManagedAppActivated(yt);
    p.onVerifiedDisconnected(5);
    p.restoreLastAppFromExistingPreferences("com.fake.absent");
    assert(p.onVerifiedConnected("",installed).empty());
}
static void testDisconnectOffNeverCloses() {
    Policy p; p.onVerifiedConnected("",installed); p.onManagedAppActivated(yt);
    p.onVerifiedDisconnected(20);
    assert(!p.hasPendingClose());
    assert(p.tick(50000,true,own).empty());
}
static void testGraceAndNoDoubleClose() {
    Policy p; p.setCloseOnDisconnect(true);
    p.onVerifiedConnected("",installed); p.onManagedAppActivated(yt);
    p.onManagedAppActivated(map);
    p.onVerifiedDisconnected(100);
    assert(p.hasPendingClose() && p.closeDueAtMs()==12100);
    assert(p.tick(12099,true,own).empty());
    auto a=p.tick(12100,true,own);
    assert(a.size()==2 && a[0].kind==ActionKind::TerminateOwnedApp);
    assert(p.tick(99999,true,own).empty());
}
static void testReconnectCancelsTimer() {
    Policy p; p.setCloseOnDisconnect(true);
    p.onVerifiedConnected("",installed); p.onManagedAppActivated(yt);
    p.onVerifiedDisconnected(100);
    p.onVerifiedConnected(yt,installed);
    assert(!p.hasPendingClose());
    assert(p.tick(20000,true,own).empty());
}
static void testRecheckRealConnectionAndOwnership() {
    Policy p; p.setCloseOnDisconnect(true);
    p.onVerifiedConnected("",installed); p.onManagedAppActivated(yt);
    p.onVerifiedDisconnected(10);
    assert(p.tick(12010,false,own).empty()); // stale disconnect signal, screen still connected
    assert(!p.hasPendingClose());
    p.onVerifiedConnected("",installed); p.onManagedAppActivated(yt);p.onVerifiedDisconnected(50000);
    assert(p.tick(62000,true,[](const std::string&){return false;}).empty());
}
static void testToggleOffCancelsPendingClose() {
    Policy p; p.setCloseOnDisconnect(true);
    p.onVerifiedConnected("",installed); p.onManagedAppActivated(yt);
    p.onVerifiedDisconnected(10);
    assert(p.hasPendingClose());
    p.setCloseOnDisconnect(false);
    assert(!p.hasPendingClose());
    assert(p.tick(20000,true,own).empty());
}
static void testAutostartAndCloseIndependent() {
    Policy p; p.setCloseOnDisconnect(true);
    p.restoreLastAppFromExistingPreferences(yt);
    assert(p.onVerifiedConnected("",installed).empty()); // autostart still OFF
    assert(p.onManagedAppActivated(yt).size()==0);
    p.onVerifiedDisconnected(100);
    auto a=p.tick(12100,true,own);
    assert(a.size()==1 && a[0].bundleId==yt);
}
int main() {
    testAutoOffDoesNothing();
    testAutoOnRestoresOnceOnly();
    testRememberLastAppInSameSwitch();
    testDisableDuringReconnect();
    testRejectUnknownApps();
    testDisconnectOffNeverCloses();
    testGraceAndNoDoubleClose();
    testReconnectCancelsTimer();
    testRecheckRealConnectionAndOwnership();
    testToggleOffCancelsPendingClose();
    testAutostartAndCloseIndependent();
    std::cout << "PASS: 11 DuoFace connection policy scenarios, no DEB touched\n";
}
