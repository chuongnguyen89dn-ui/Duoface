#include "DFSPDisplayState.h"
#include <stddef.h>
#include <string.h>

/* Reuses the old DuoFace/Airaw two-owner transition order, NOT their
   proprietary runtime or CB bridge. Callers must verify each owner ACK. */
void DFSPDisplayInit(DFSPDisplay *s) {
    if (!s) return;
    memset(s, 0, sizeof(*s));
    s->mode = DFSP_OFFLINE;
}
static DFSPStep next(DFSPDisplay *s, DFSPStep step) {
    s->waiting = step;
    return step;
}
DFSPStep DFSPDisplayConnect(DFSPDisplay *s) {
    if (!s || s->connected) return DFSP_NONE;
    s->transaction++;
    s->connected = true;
    s->mode = DFSP_RESTORING_STARTUP;
    s->barHiddenConfirmed = false;
    s->hostFullConfirmed = false;
    /* Always show system bar first, then set usable host geometry. */
    return next(s, DFSP_SHOW_SYSTEM_BAR);
}
DFSPStep DFSPDisplayZoomIn(DFSPDisplay *s) {
    if (!s || !s->connected || s->mode != DFSP_NORMAL ||
        s->waiting != DFSP_NONE) return DFSP_NONE;
    s->mode = DFSP_ENTERING;
    s->transaction++;
    return next(s, DFSP_APPLY_HOST_FULL);
}
DFSPStep DFSPDisplayZoomOut(DFSPDisplay *s) {
    if (!s || !s->connected || s->mode != DFSP_FULL ||
        s->waiting != DFSP_NONE) return DFSP_NONE;
    s->mode = DFSP_EXITING;
    s->transaction++;
    return next(s, DFSP_SHOW_SYSTEM_BAR);
}
DFSPStep DFSPDisplayAck(DFSPDisplay *s, uint64_t transaction,
                         DFSPStep completed, bool success) {
    if (!s || !s->connected || !transaction ||
        transaction != s->transaction || s->waiting != completed ||
        completed == DFSP_NONE) return DFSP_NONE;
    s->waiting = DFSP_NONE;
    if (!success) {
        if (s->mode == DFSP_RECOVERING) {
            s->mode = DFSP_UNVERIFIED;
            return DFSP_NONE;
        }
        s->mode = DFSP_RECOVERING;
        return next(s, DFSP_SHOW_SYSTEM_BAR);
    }
    if (completed == DFSP_SHOW_SYSTEM_BAR) s->barHiddenConfirmed = false;
    if (completed == DFSP_HIDE_SYSTEM_BAR) s->barHiddenConfirmed = true;
    if (completed == DFSP_APPLY_HOST_FULL) s->hostFullConfirmed = true;
    if (completed == DFSP_APPLY_HOST_NORMAL) s->hostFullConfirmed = false;
    switch (s->mode) {
    case DFSP_RESTORING_STARTUP:
        if (completed == DFSP_SHOW_SYSTEM_BAR)
            return next(s, DFSP_APPLY_HOST_NORMAL);
        if (completed == DFSP_APPLY_HOST_NORMAL) {
            s->mode = DFSP_NORMAL;
            return DFSP_NONE;
        }
        break;
    case DFSP_ENTERING:
        if (completed == DFSP_APPLY_HOST_FULL)
            return next(s, DFSP_HIDE_SYSTEM_BAR);
        if (completed == DFSP_HIDE_SYSTEM_BAR) {
            s->mode = DFSP_FULL;
            return DFSP_NONE;
        }
        break;
    case DFSP_EXITING:
        if (completed == DFSP_SHOW_SYSTEM_BAR)
            return next(s, DFSP_APPLY_HOST_NORMAL);
        if (completed == DFSP_APPLY_HOST_NORMAL) {
            s->mode = DFSP_NORMAL;
            return DFSP_NONE;
        }
        break;
    case DFSP_RECOVERING:
        if (completed == DFSP_SHOW_SYSTEM_BAR)
            return next(s, DFSP_APPLY_HOST_NORMAL);
        if (completed == DFSP_APPLY_HOST_NORMAL) {
            s->mode = DFSP_NORMAL;
            return DFSP_NONE;
        }
        break;
    default: break;
    }
    s->mode = DFSP_UNVERIFIED;
    return DFSP_NONE;
}
void DFSPDisplayDisconnect(DFSPDisplay *s) {
    if (!s) return;
    s->transaction++; /* discard ACKs from previous CarPlay session */
    s->connected = false;
    s->hostFullConfirmed = false;
    s->barHiddenConfirmed = false;
    s->waiting = DFSP_NONE;
    s->mode = DFSP_OFFLINE;
    /* Platform owner MUST independently release window + native chrome on
       disconnect, before disposing its scene. No callbacks can be sent here. */
}
bool DFSPDisplayIsFull(const DFSPDisplay *s) {
    return s && s->connected && s->mode == DFSP_FULL &&
           s->hostFullConfirmed && s->barHiddenConfirmed;
}
const char *DFSPDisplayZoomLabel(const DFSPDisplay *s) {
    return DFSPDisplayIsFull(s) ? "Zoom Out" : "Zoom In";
}
