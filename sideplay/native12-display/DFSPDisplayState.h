#ifndef DFSP_DISPLAY_STATE_H
#define DFSP_DISPLAY_STATE_H
#include <stdbool.h>
#include <stdint.h>
/* UI-only transaction policy for the complete CarPlay display; no split API. */
typedef enum {
    DFSP_OFFLINE, DFSP_RESTORING_STARTUP, DFSP_NORMAL,
    DFSP_ENTERING, DFSP_FULL, DFSP_EXITING, DFSP_RECOVERING, DFSP_UNVERIFIED
} DFSPMode;
typedef enum {
    DFSP_NONE, DFSP_APPLY_HOST_NORMAL, DFSP_APPLY_HOST_FULL,
    DFSP_SHOW_SYSTEM_BAR, DFSP_HIDE_SYSTEM_BAR
} DFSPStep;
typedef struct {
    DFSPMode mode;
    DFSPStep waiting;
    uint64_t transaction;
    bool connected;
    bool hostFullConfirmed;
    bool barHiddenConfirmed;
} DFSPDisplay;
/* Caller performs each step on its real host/chrome owner and calls Ack. */
void DFSPDisplayInit(DFSPDisplay *s);
DFSPStep DFSPDisplayConnect(DFSPDisplay *s);
DFSPStep DFSPDisplayZoomIn(DFSPDisplay *s);
DFSPStep DFSPDisplayZoomOut(DFSPDisplay *s);
DFSPStep DFSPDisplayAck(DFSPDisplay *s, uint64_t transaction,
                        DFSPStep completed, bool success);
void DFSPDisplayDisconnect(DFSPDisplay *s);
bool DFSPDisplayIsFull(const DFSPDisplay *s);
const char *DFSPDisplayZoomLabel(const DFSPDisplay *s);
#endif
