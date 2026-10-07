import Foundation
import Security
import iKeypadShared

/// Where the Mac keeps the token of each paired iPad.
protocol PairedDeviceStore: AnyObject {
    func token(for clientId: String) -> Data?
    func save(token: Data, for clientId: String, name: String) throws
    func removeAll() throws
    var count: Int { get }
}

/// Paired iPads' tokens in the login Keychain, one generic password per iPad.
final class KeychainPairedDeviceStore: PairedDeviceStore {
    enum Failure: Error { case keychain(OSStatus) }

    private let service = "com.hoque.sidekey.paired-ipads"

    func token(for clientId: String) -> Data? {
        var result: CFTypeRef?
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: clientId,
                                    kSecReturnData as String: true]
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    func save(token: Data, for clientId: String, name: String) throws {
        let match: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: clientId]
        SecItemDelete(match as CFDictionary)
        var item = match
        item[kSecValueData as String] = token
        item[kSecAttrLabel as String] = "Sidekey pairing: \(name)"
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw Failure.keychain(status) }
    }

    func removeAll() throws {
        let status = SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw Failure.keychain(status) }
    }

    var count: Int {
        var result: CFTypeRef?
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecMatchLimit as String: kSecMatchLimitAll,
                                    kSecReturnAttributes as String: true]
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return 0 }
        return (result as? [[String: Any]])?.count ?? 0
    }
}

/// Paired iPads kept in memory only; tests use this so they never touch the real Keychain.
final class InMemoryPairedDeviceStore: PairedDeviceStore {
    private var tokens: [String: Data] = [:]
    func token(for clientId: String) -> Data? { tokens[clientId] }
    func save(token: Data, for clientId: String, name: String) throws { tokens[clientId] = token }
    func removeAll() throws { tokens.removeAll() }
    var count: Int { tokens.count }
}

/// The short window in which the Mac accepts a pairing code.
///
/// The code exists only after the user chooses Pair iPad in the menu, lasts ``lifetime``
/// seconds, and closes after ``maxAttempts`` wrong guesses across all connections, so it cannot
/// be brute-forced.
@MainActor
final class PairingWindow: ObservableObject {
    enum Outcome: Equatable { case accepted, wrong, closed }

    static let lifetime: TimeInterval = 120
    static let maxAttempts = 5

    @Published private(set) var code: String?
    @Published private(set) var expiresAt: Date?
    private var attemptsLeft = 0

    var isOpen: Bool { code != nil }

    /// Open the window with a fresh code.
    func open(now: Date = Date()) throws {
        code = try PairingCrypto.pairingCode()
        expiresAt = now.addingTimeInterval(Self.lifetime)
        attemptsLeft = Self.maxAttempts
    }

    func close() {
        code = nil
        expiresAt = nil
        attemptsLeft = 0
    }

    /// Check a code from an iPad. A correct code closes the window so it can be used only once.
    func attempt(_ candidate: String, now: Date = Date()) -> Outcome {
        guard let code, let expiresAt, now < expiresAt, attemptsLeft > 0 else {
            close()
            return .closed
        }
        if Self.constantTimeEqual(candidate, code) {
            close()
            return .accepted
        }
        attemptsLeft -= 1
        if attemptsLeft == 0 { close() }
        return .wrong
    }

    private static func constantTimeEqual(_ a: String, _ b: String) -> Bool {
        let x = Array(a.utf8), y = Array(b.utf8)
        guard x.count == y.count else { return false }
        return zip(x, y).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

/// This Mac's stable identity, advertised over Bonjour so a paired iPad reconnects only to it.
enum HostIdentity {
    static var current: String {
        let key = "hostId"
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
