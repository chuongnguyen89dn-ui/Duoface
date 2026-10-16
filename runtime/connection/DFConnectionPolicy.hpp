#pragma once
// DuoFace-owned connection policy. No UIKit/CarPlay/private API dependencies.
// Adapter must feed VERIFIED events only and recheck app ownership before action.
#include <cstdint>
#include <functional>
#include <set>
#include <string>
#include <vector>

namespace duoface { namespace connection {
enum class ActionKind { LaunchApp, TerminateOwnedApp, SaveLastApp };
struct Action {
    ActionKind kind;
    std::string bundleId;
    std::uint64_t generation;
};
class Policy {
public:
    static constexpr std::uint64_t kDisconnectGraceMs = 12000;
    using Predicate = std::function<bool(const std::string&)>;
    void setAutoStart(bool enabled);
    void setCloseOnDisconnect(bool enabled);
    bool autoStartEnabled() const { return autoStart_; }
    bool closeOnDisconnectEnabled() const { return closeOnDisconnect_; }
    bool connected() const { return connected_; }
    std::uint64_t generation() const { return generation_; }
    const std::string& lastApp() const { return lastApp_; }
    void restoreLastAppFromExistingPreferences(const std::string& bundleId);
    // Returns SaveLastApp exactly when the last *verified managed* app changes.
    std::vector<Action> onManagedAppActivated(const std::string& bundleId);
    // existingDuoFaceApp is verified owned and already running, or empty.
    // installed checks candidate bundle against actual installed applications.
    std::vector<Action> onVerifiedConnected(const std::string& existingDuoFaceApp,
                                            const Predicate& installed);
    void onVerifiedDisconnected(std::uint64_t monotonicMs);
    bool hasPendingClose() const { return pendingClose_; }
    std::uint64_t closeDueAtMs() const { return dueAtMs_; }
    // confirmedDisconnected must re-query the real CarPlay owner, not infer
    // a route change. canTerminate must recheck bundle ownership/running state.
    std::vector<Action> tick(std::uint64_t monotonicMs,
                             bool confirmedDisconnected,
                             const Predicate& canTerminate);
    static bool validBundleId(const std::string& s);
private:
    bool autoStart_ = false;
    bool closeOnDisconnect_ = false;
    bool connected_ = false;
    bool pendingClose_ = false;
    std::uint64_t generation_ = 0;
    std::uint64_t dueAtMs_ = 0;
    std::string lastApp_;
    std::string pendingLaunch_;
    std::set<std::string> sessionOwnedApps_;
    std::set<std::string> pendingOwnedApps_;
    void clearPendingClose();
};
}} // namespace duoface::connection
