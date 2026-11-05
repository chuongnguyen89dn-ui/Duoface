#include "../DFDisconnectTimerPolicy.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
    // A disconnect at t=0 queues A's 10-second callback. Reconnect cancels A;
    // B becomes active and disconnects at t=3, queuing its own callback.
    // The old A callback at t=10 must not cancel B's pending close at t=13.
    uint64_t generation = 1;
    const uint64_t timerA = ++generation;
    ++generation; // A reconnect cancellation.
    ++generation; // B's new active session.
    const uint64_t timerB = ++generation;
    assert(DFDisconnectTimerDecide(timerA, generation, false, false)
           == DFDisconnectTimerIgnoreStale);
    // Ignoring A leaves B as the current owner, which may execute at its own
    // deadline. The decision below is the same function production calls.
    assert(generation == timerB);
    assert(DFDisconnectTimerDecide(timerB, generation, true, true)
           == DFDisconnectTimerExecute);

    // Stale work is ignored even if its old execution eligibility was true,
    // or a session identifier happens to match. Either identity check fails
    // closed before the current-session cancellation decision is considered.
    assert(DFDisconnectTimerDecide(timerA, generation, false, true)
           == DFDisconnectTimerIgnoreStale);
    assert(DFDisconnectTimerDecide(timerA, generation, true, false)
           == DFDisconnectTimerIgnoreStale);
    assert(DFDisconnectTimerDecide(timerA, generation, true, true)
           == DFDisconnectTimerIgnoreStale);
    assert(DFDisconnectTimerDecide(timerB, generation, false, false)
           == DFDisconnectTimerIgnoreStale);
    assert(DFDisconnectTimerDecide(timerB, generation, false, true)
           == DFDisconnectTimerIgnoreStale);

    // Reconnect, disabling the policy or a failed grace-period check still
    // cancels the current session when THIS callback retains ownership.
    assert(DFDisconnectTimerDecide(timerB, generation, true, false)
           == DFDisconnectTimerCancelCurrent);

    // A termination request has consumed the one-shot session/candidates, but
    // its repeated exit-verification callback still belongs to timerB's
    // generation. A new session, reconnect or disabled policy must stop that
    // callback BEFORE it can publish a stale exit/timeout ACK.
    assert(DFDisconnectVerificationMayContinue(timerB,generation,true,true));
    ++generation; // A new active session starts while an old PID is checked.
    assert(!DFDisconnectVerificationMayContinue(timerB,generation,true,true));
    assert(!DFDisconnectVerificationMayContinue(timerB,timerB,false,true));
    assert(!DFDisconnectVerificationMayContinue(timerB,timerB,true,false));
    assert(!DFDisconnectVerificationMayContinue(timerB,timerB,false,false));
    // The unchanged valid path still reaches the real PID/exit checks.
    assert(DFDisconnectVerificationMayContinue(timerB,timerB,true,true));
    puts("DF_DISCONNECT_TIMER_POLICY_RUNTIME_PASS");
    return 0;
}
