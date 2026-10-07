import Foundation
import Cocoa
import Combine
import iKeypadShared

@MainActor
public final class AppContextMonitor: ObservableObject {
    public static let shared = AppContextMonitor()

    @Published public private(set) var activeBundleId: String = ""
    @Published public private(set) var activeAppName: String = "Finder"
    /// Internal setter so tests can install a harmless layout; the app sets it only from focus changes.
    @Published public internal(set) var activeProfile: DeckProfile

    /// Fires with a fresh ``AppContext`` whenever the frontmost app, its window title or its
    /// chips change. The icon is included only when the app itself changed.
    public let contextChanges = PassthroughSubject<AppContext, Never>()

    private var profileRegistry: [String: DeckProfile] = [:]
    private let defaultProfile: DeckProfile
    private var activeApp: NSRunningApplication?
    private var lastContext: AppContext?
    private var pollTimer: Timer?
    private static let pollInterval: TimeInterval = 1.0

    private init() {
        self.defaultProfile = DefaultProfiles.makeDefaultFallbackProfile()
        self.activeProfile = defaultProfile

        // Register defaults
        for prof in DefaultProfiles.allDefaultProfiles() {
            register(profile: prof)
        }

        setupObserver()
        checkCurrentFrontmostApp()
    }

    public func register(profile: DeckProfile) {
        profileRegistry[profile.appBundleIdentifier] = profile
    }

    /// The registered profile with ``id``, including the fallback profile.
    public func profile(withId id: String) -> DeckProfile? {
        if defaultProfile.id == id { return defaultProfile }
        return profileRegistry.values.first { $0.id == id }
    }

    /// Full context for the current app, icon included, for a client that just connected.
    public func currentContext() -> AppContext? {
        guard let app = activeApp else { return nil }
        return makeContext(for: app, includeIcon: true)
    }

    /// Poll window titles and chips only while at least one iPad is connected.
    public func setPolling(_ enabled: Bool) {
        if enabled, pollTimer == nil {
            pollTimer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in self?.publishContextIfChanged(appChanged: false) }
            }
        } else if !enabled {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private func setupObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleId = app.bundleIdentifier else { return }

                self.activeApp = app
                self.updateActiveApp(bundleId: bundleId, appName: app.localizedName ?? bundleId)
                self.publishContextIfChanged(appChanged: true)
            }
        }
    }

    private func checkCurrentFrontmostApp() {
        if let currentApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = currentApp.bundleIdentifier {
            activeApp = currentApp
            updateActiveApp(bundleId: bundleId, appName: currentApp.localizedName ?? bundleId)
        }
    }

    private func updateActiveApp(bundleId: String, appName: String) {
        self.activeBundleId = bundleId
        self.activeAppName = appName

        if let matchingProfile = profileRegistry[bundleId] {
            self.activeProfile = matchingProfile
            print("[Context] Switched to profile for \(appName) (\(bundleId))")
        } else {
            // Fallback default profile
            self.activeProfile = defaultProfile
            print("[Context] No custom profile for \(appName) (\(bundleId)), using default")
        }
    }

    private func makeContext(for app: NSRunningApplication, includeIcon: Bool) -> AppContext {
        AppContext(
            bundleIdentifier: app.bundleIdentifier ?? "",
            appName: app.localizedName ?? app.bundleIdentifier ?? "Unknown app",
            windowTitle: AppStateReader.focusedWindowTitle(of: app),
            iconPNG: includeIcon ? AppStateReader.iconPNG(of: app) : nil,
            accessibilityTrusted: AppStateReader.isAccessibilityTrusted,
            chips: AppStateReader.chips(for: app)
        )
    }

    private func publishContextIfChanged(appChanged: Bool) {
        guard let app = activeApp else { return }
        let context = makeContext(for: app, includeIcon: appChanged)
        let unchanged = !appChanged
            && lastContext?.bundleIdentifier == context.bundleIdentifier
            && lastContext?.windowTitle == context.windowTitle
            && lastContext?.chips == context.chips
            && lastContext?.accessibilityTrusted == context.accessibilityTrusted
        guard !unchanged else { return }
        lastContext = context
        contextChanges.send(context)
    }
}
