#include "../DFSPDisplayState.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static void ack(DFSPDisplay *s, DFSPStep step, bool result,
                DFSPStep expected) {
    uint64_t epoch=s->transaction;
    assert(s->waiting==step);
    assert(DFSPDisplayAck(s,epoch,step,result)==expected);
}
static void boot(DFSPDisplay *s) {
    DFSPDisplayInit(s);
    assert(DFSPDisplayConnect(s)==DFSP_SHOW_SYSTEM_BAR);
    assert(!DFSPDisplayIsFull(s));
    assert(DFSPDisplayZoomIn(s)==DFSP_NONE);
    ack(s,DFSP_SHOW_SYSTEM_BAR,true,DFSP_APPLY_HOST_NORMAL);
    ack(s,DFSP_APPLY_HOST_NORMAL,true,DFSP_NONE);
    assert(s->mode==DFSP_NORMAL);
    assert(strcmp(DFSPDisplayZoomLabel(s),"Zoom In")==0);
}
static void test_explicit_zoom(void) {
    DFSPDisplay s; boot(&s);
    assert(DFSPDisplayZoomIn(&s)==DFSP_APPLY_HOST_FULL);
    assert(s.mode==DFSP_ENTERING && !DFSPDisplayIsFull(&s));
    ack(&s,DFSP_APPLY_HOST_FULL,true,DFSP_HIDE_SYSTEM_BAR);
    assert(!DFSPDisplayIsFull(&s));
    ack(&s,DFSP_HIDE_SYSTEM_BAR,true,DFSP_NONE);
    assert(DFSPDisplayIsFull(&s));
    assert(strcmp(DFSPDisplayZoomLabel(&s),"Zoom Out")==0);
    assert(DFSPDisplayZoomOut(&s)==DFSP_SHOW_SYSTEM_BAR);
    assert(DFSPDisplayZoomOut(&s)==DFSP_NONE);
    ack(&s,DFSP_SHOW_SYSTEM_BAR,true,DFSP_APPLY_HOST_NORMAL);
    ack(&s,DFSP_APPLY_HOST_NORMAL,true,DFSP_NONE);
    assert(s.mode==DFSP_NORMAL && !DFSPDisplayIsFull(&s));
}
static void test_failed_enter_restores(void) {
    DFSPDisplay s; boot(&s);
    assert(DFSPDisplayZoomIn(&s)==DFSP_APPLY_HOST_FULL);
    ack(&s,DFSP_APPLY_HOST_FULL,true,DFSP_HIDE_SYSTEM_BAR);
    ack(&s,DFSP_HIDE_SYSTEM_BAR,false,DFSP_SHOW_SYSTEM_BAR);
    assert(s.mode==DFSP_RECOVERING && !DFSPDisplayIsFull(&s));
    ack(&s,DFSP_SHOW_SYSTEM_BAR,true,DFSP_APPLY_HOST_NORMAL);
    ack(&s,DFSP_APPLY_HOST_NORMAL,true,DFSP_NONE);
    assert(s.mode==DFSP_NORMAL);
}
static void test_failed_exit_never_claims_success(void) {
    DFSPDisplay s; boot(&s);
    DFSPDisplayZoomIn(&s);
    ack(&s,DFSP_APPLY_HOST_FULL,true,DFSP_HIDE_SYSTEM_BAR);
    ack(&s,DFSP_HIDE_SYSTEM_BAR,true,DFSP_NONE);
    DFSPDisplayZoomOut(&s);
    ack(&s,DFSP_SHOW_SYSTEM_BAR,false,DFSP_SHOW_SYSTEM_BAR);
    assert(s.mode==DFSP_RECOVERING);
    ack(&s,DFSP_SHOW_SYSTEM_BAR,false,DFSP_NONE);
    assert(s.mode==DFSP_UNVERIFIED && !DFSPDisplayIsFull(&s));
}
static void test_disconnect_rejects_stale_ack(void) {
    DFSPDisplay s; boot(&s);
    DFSPDisplayZoomIn(&s);
    uint64_t stale=s.transaction;
    DFSPDisplayDisconnect(&s);
    assert(s.mode==DFSP_OFFLINE && !s.connected);
    assert(DFSPDisplayAck(&s,stale,DFSP_APPLY_HOST_FULL,true)==DFSP_NONE);
    assert(DFSPDisplayConnect(&s)==DFSP_SHOW_SYSTEM_BAR);
    assert(DFSPDisplayAck(&s,stale,DFSP_SHOW_SYSTEM_BAR,true)==DFSP_NONE);
    assert(s.mode==DFSP_RESTORING_STARTUP && !DFSPDisplayIsFull(&s));
}
static void test_rejects_unknown_transaction(void) {
    DFSPDisplay s; boot(&s);
    DFSPDisplayZoomIn(&s);
    assert(DFSPDisplayAck(&s,s.transaction+5,DFSP_APPLY_HOST_FULL,true)==DFSP_NONE);
    assert(s.mode==DFSP_ENTERING && s.waiting==DFSP_APPLY_HOST_FULL);
    assert(DFSPDisplayAck(&s,s.transaction,DFSP_SHOW_SYSTEM_BAR,true)==DFSP_NONE);
}
int main(void) {
    test_explicit_zoom();
    test_failed_enter_restores();
    test_failed_exit_never_claims_success();
    test_disconnect_rejects_stale_ack();
    test_rejects_unknown_transaction();
    puts("5 Native12 whole-screen display tests PASS (no SidePlay host execution)");
    return 0;
}
