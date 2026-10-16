#include "DFConnectionPolicy.hpp"
#include <algorithm>
#include <cctype>
#include <limits>
#include <utility>

namespace duoface { namespace connection {
bool Policy::validBundleId(const std::string& s) {
    if (s.size() < 3 || s.size() > 255 || s.front() == '.' || s.back() == '.'
        || s.find('.') == std::string::npos || s.find("..") != std::string::npos)
        return false;
    for (unsigned char c : s) {
        if (!(std::isalnum(c) || c == '.' || c == '-' || c == '_'))
            return false;
    }
    return true;
}
void Policy::clearPendingClose() {
    pendingClose_ = false;
    dueAtMs_ = 0;
    pendingOwnedApps_.clear();
}
void Policy::setAutoStart(bool enabled) {
    autoStart_ = enabled;
    if (!enabled) pendingLaunch_.clear();
}
void Policy::setCloseOnDisconnect(bool enabled) {
    closeOnDisconnect_ = enabled;
    if (!enabled) clearPendingClose();  // user switches OFF during grace
}
void Policy::restoreLastAppFromExistingPreferences(const std::string& id) {
    // Preference adapter owns the domain; never overwrite the old key here.
    lastApp_ = validBundleId(id) ? id : std::string();
}
std::vector<Action> Policy::onManagedAppActivated(const std::string& id) {
    if (!connected_ || !validBundleId(id)) return {};
    sessionOwnedApps_.insert(id);
    pendingLaunch_.clear();
    if (lastApp_ == id) return {};
    lastApp_ = id;
    return {{ActionKind::SaveLastApp, lastApp_, generation_}};
}
std::vector<Action> Policy::onVerifiedConnected(const std::string& activeOwnedApp,
                                                 const Predicate& installed) {
    if (connected_) return {};  // duplicate event: never launch twice
    connected_ = true;
    ++generation_;             // invalidate all stale disconnect callbacks
    auto previouslyOwned = pendingOwnedApps_;
    clearPendingClose();
    pendingLaunch_.clear();
    sessionOwnedApps_.clear();
    if (validBundleId(activeOwnedApp)) {
        sessionOwnedApps_.insert(activeOwnedApp);
        // The active app is already on the display; no new launch.
        return onManagedAppActivated(activeOwnedApp);
    }
    // A pending app from before a short disconnect is not proof of a currently
    // running app, and does not establish ownership for the *new* session.
    (void)previouslyOwned;
    if (!autoStart_ || !validBundleId(lastApp_) || !installed || !installed(lastApp_))
        return {};
    pendingLaunch_ = lastApp_;
    return {{ActionKind::LaunchApp, lastApp_, generation_}};
}
void Policy::onVerifiedDisconnected(std::uint64_t now) {
    if (!connected_) return;
    connected_ = false;
    ++generation_;
    pendingLaunch_.clear();
    if (!closeOnDisconnect_ || sessionOwnedApps_.empty()) {
        clearPendingClose();
        sessionOwnedApps_.clear();
        return;
    }
    pendingOwnedApps_ = sessionOwnedApps_;
    sessionOwnedApps_.clear();
    // Saturate rather than let a wrapped tick appear immediately due.
    dueAtMs_ = now > std::numeric_limits<std::uint64_t>::max()-kDisconnectGraceMs
        ? std::numeric_limits<std::uint64_t>::max() : now+kDisconnectGraceMs;
    pendingClose_ = true;
}
std::vector<Action> Policy::tick(std::uint64_t now, bool confirmedDisconnected,
                                 const Predicate& canTerminate) {
    if (connected_ || !pendingClose_ || now < dueAtMs_) return {};
    auto candidates = pendingOwnedApps_;
    clearPendingClose(); // at most once, even if callback retries
    if (!closeOnDisconnect_ || !confirmedDisconnected || !canTerminate)
        return {};
    std::vector<Action> result;
    for (const auto& id : candidates) {
        if (validBundleId(id) && canTerminate(id))
            result.push_back({ActionKind::TerminateOwnedApp,id,generation_});
    }
    return result;
}
}} // namespace duoface::connection
