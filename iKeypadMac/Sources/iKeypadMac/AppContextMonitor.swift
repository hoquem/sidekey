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

    /// The layout each app starts in, by bundle identifier.
    private var profileRegistry: [String: DeckProfile] = [:]
    /// Every layout by id, including the extra modes of apps that have several (Citrix Viewer).
    private var profilesById: [String: DeckProfile] = [:]
    /// The mode last chosen for an app, by bundle identifier; it survives switching apps.
    private var modeByBundle: [String: String] = [:]
    /// The layouts as shipped, untouched by the user: the bases user layouts apply to, and what
    /// ``uninstall(layoutId:)`` restores.
    let builtInProfiles: [DeckProfile]
    /// Ids of the user layouts installed by the last ``reloadUserLayouts(from:)``.
    private var userLayoutIds: Set<String> = []
    /// User layout files the last reload refused, with the reason, for the menu and the editor.
    @Published private(set) var layoutFileErrors: [LayoutFileError] = []
    private var defaultProfile: DeckProfile
    private var activeApp: NSRunningApplication?
    private var lastContext: AppContext?
    private var pollTimer: Timer?
    private static let pollInterval: TimeInterval = 1.0

    private init() {
        self.defaultProfile = DefaultProfiles.makeDefaultFallbackProfile()
        self.activeProfile = defaultProfile
        self.builtInProfiles = DefaultProfiles.allDefaultProfiles()
        for prof in builtInProfiles {
            register(profile: prof)
        }

        setupObserver()
        checkCurrentFrontmostApp()
    }

    /// Register a layout. The first layout registered for an app is the one it starts in; later
    /// ones are extra modes, reached with ``switchMode(to:)``.
    public func register(profile: DeckProfile) {
        profilesById[profile.id] = profile
        if profileRegistry[profile.appBundleIdentifier] == nil {
            profileRegistry[profile.appBundleIdentifier] = profile
        }
    }

    /// The registered profile with ``id``, including the fallback profile.
    public func profile(withId id: String) -> DeckProfile? {
        if defaultProfile.id == id { return defaultProfile }
        return profilesById[id]
    }

    /// The built-in layout with ``id`` as shipped, ignoring any user layout.
    func builtInProfile(withId id: String) -> DeckProfile? {
        builtInProfiles.first { $0.id == id }
    }

    /// Show a layout in place of the one with the same id: a built-in layout (as the app's start
    /// layout too, when it is that) or a new app's layout. When it is on screen it is reassigned
    /// to ``activeProfile``, which the server already sends to every iPad.
    ///
    /// :param profile: The layout to show.
    func install(_ profile: DeckProfile) {
        profilesById[profile.id] = profile
        if profile.id == defaultProfile.id { defaultProfile = profile }
        let bundle = profile.appBundleIdentifier
        if profileRegistry[bundle] == nil || profileRegistry[bundle]?.id == profile.id {
            profileRegistry[bundle] = profile
        }
        if activeProfile.id == profile.id { activeProfile = profile }
    }

    /// Undo ``install(_:)``: the built-in layout with ``layoutId`` comes back, or a new app's
    /// layout is removed and that app falls back to the System layout.
    ///
    /// :param layoutId: The id of the layout to uninstall.
    func uninstall(layoutId: String) {
        if let builtIn = builtInProfile(withId: layoutId) {
            install(builtIn)
            return
        }
        guard let removed = profilesById.removeValue(forKey: layoutId) else { return }
        let bundle = removed.appBundleIdentifier
        if profileRegistry[bundle]?.id == layoutId { profileRegistry[bundle] = nil }
        if modeByBundle[bundle] == layoutId { modeByBundle[bundle] = nil }
        if activeProfile.id == layoutId { updateActiveApp(bundleId: activeBundleId, appName: activeAppName) }
    }

    /// Replace every installed user layout with the valid files in a store, and record the files
    /// that were refused in ``layoutFileErrors``.
    ///
    /// :param store: The folder of user layout files to load.
    func reloadUserLayouts(from store: UserLayoutStore) {
        for id in userLayoutIds { uninstall(layoutId: id) }
        let loaded = store.loadAll(builtIns: builtInProfiles)
        for customisation in loaded.customisations {
            install(LayoutResolver.resolve(customisation, base: builtInProfile(withId: customisation.layoutId)))
        }
        userLayoutIds = Set(loaded.customisations.map(\.layoutId))
        layoutFileErrors = loaded.errors
    }

    /// Show another mode of the app in front, such as Citrix Viewer's Outlook keys.
    ///
    /// :param profileId: A layout registered for the frontmost app.
    /// :returns: ``false`` when ``profileId`` is unknown or belongs to another app; nothing changes.
    @discardableResult
    func switchMode(to profileId: String) -> Bool {
        guard let profile = profilesById[profileId], profile.appBundleIdentifier == activeBundleId else { return false }
        modeByBundle[activeBundleId] = profileId
        activeProfile = profile
        print("[Context] Switched \(activeAppName) to mode \(profileId)")
        publishContextIfChanged(appChanged: false)
        return true
    }

    /// The chip naming the active mode of an app with several, bound to the mode row key that
    /// leads to it so the iPad lights that key: the mode's own key, or for a mode picked under
    /// More, the More key. ``nil`` for apps with a single layout.
    func modeChip(for profile: DeckProfile) -> ContextChip? {
        let ownKey = profile.keys.first { $0.action == .switchProfile(profileId: profile.id) }
        let pickerKey = profile.keys.first { key in
            guard case .switchProfile(let pickerId) = key.action, let picker = profilesById[pickerId] else { return false }
            return picker.keys.contains { $0.action == .switchProfile(profileId: profile.id) }
        }
        guard let rowKey = ownKey ?? pickerKey, case .switchProfile(let rowModeId) = rowKey.action else { return nil }
        let name = ownKey?.label ?? profilesById[rowModeId]?.keys.first { $0.action == .switchProfile(profileId: profile.id) }?.label ?? rowKey.label
        // An attention tone is what lights a bound key on the iPad.
        return ContextChip(id: "mode.\(rowModeId)", label: "\(name) mode",
                           systemImage: rowKey.iconSystemName ?? "square.grid.2x2", tone: .warn, isOn: true)
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

    /// Internal so tests can drive app switches; the app calls it only from focus changes.
    func updateActiveApp(bundleId: String, appName: String) {
        self.activeBundleId = bundleId
        self.activeAppName = appName

        if let mode = modeByBundle[bundleId], let modeProfile = profilesById[mode] {
            self.activeProfile = modeProfile
            print("[Context] Switched to profile for \(appName) (\(bundleId)), mode \(mode)")
        } else if let matchingProfile = profileRegistry[bundleId] {
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
            chips: AppStateReader.chips(for: app) + [modeChip(for: activeProfile)].compactMap { $0 }
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
