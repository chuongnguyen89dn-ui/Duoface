// First-party callback ownership is independent of presentation visibility.
// A hidden/detached pane loses its presentation lease, not the controller's
// manual lifecycle contract. Identity must still match the current handle.
#ifndef DF_MANUAL_OBSERVER_CONTRACT_H
#define DF_MANUAL_OBSERVER_CONTRACT_H
#include <stdbool.h>
static inline bool DFManualObserverOwnsCallback(bool mainThread,
    bool registeredController, bool currentHandleMatches,
    bool currentSceneExists, bool manualABIValid, bool automaticLifecycle) {
    return mainThread && registeredController && currentHandleMatches &&
           currentSceneExists && manualABIValid && !automaticLifecycle;
}
#endif
