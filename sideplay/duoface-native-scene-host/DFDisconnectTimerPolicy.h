#ifndef DF_DISCONNECT_TIMER_POLICY_H
#define DF_DISCONNECT_TIMER_POLICY_H
#include <stdbool.h>
#include <stdint.h>

typedef enum {
    DFDisconnectTimerIgnoreStale,
    DFDisconnectTimerCancelCurrent,
    DFDisconnectTimerExecute
} DFDisconnectTimerAction;

// A dispatch_after block survives reconnect/cancel. Only the block that still
// owns the current generation AND session may cancel or consume that state.
static inline DFDisconnectTimerAction DFDisconnectTimerDecide(
    uint64_t expectedGeneration, uint64_t currentGeneration,
    bool sessionMatches, bool mayExecute) {
    if (expectedGeneration != currentGeneration || !sessionMatches)
        return DFDisconnectTimerIgnoreStale;
    return mayExecute ? DFDisconnectTimerExecute : DFDisconnectTimerCancelCurrent;
}

// Termination verification outlives the one-shot candidates/session snapshot.
// Its ticks may publish an ACK only while the original generation is current,
// the physical link is still absent and the user's policy remains enabled.
static inline bool DFDisconnectVerificationMayContinue(
    uint64_t expectedGeneration, uint64_t currentGeneration,
    bool disconnected, bool enabled) {
    return expectedGeneration == currentGeneration && disconnected && enabled;
}
#endif
