import AppKit
import ServiceManagement

/// The "Launch at Login" setting, backed by macOS's own login item record for this app.
///
/// ``isEnabled`` is read from `SMAppService.mainApp.status` at start-up and after every change,
/// never set from what the user asked for: macOS can refuse or defer the change, and the checkmark
/// must show what will actually happen at the next login. Nothing here refreshes on a timer or on
/// menu appearance, because state changes while the menu renders crashed the app before (see
/// ``PairingCodeWindow``).
@MainActor
final class LaunchAtLogin: ObservableObject {
    static let shared = LaunchAtLogin()

    @Published private(set) var isEnabled: Bool

    private let service = SMAppService.mainApp

    private init() {
        isEnabled = service.status == .enabled
    }

    /// Registers or unregisters Sidekey as a login item.
    ///
    /// Failures are shown to the user in an alert. When macOS needs the user's approval, the
    /// Login Items pane of System Settings is opened so they can give it.
    ///
    /// :param enabled: ``true`` to launch Sidekey at login, ``false`` to stop doing so.
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            showFailure(enabled: enabled, error: error)
        }
        isEnabled = service.status == .enabled
        if enabled && service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    private func showFailure(enabled: Bool, error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = enabled
            ? "Sidekey couldn't be set to launch at login."
            : "Sidekey couldn't stop launching at login."
        alert.informativeText = "\(error.localizedDescription)\n\nYou can change this in System Settings › General › Login Items."
        alert.runModal()
    }
}
