import Foundation
import Security

/// What the iPad remembers about the Mac it paired with.
protocol PairingCredentials: AnyObject {
    /// This iPad's stable id, sent when pairing and authenticating.
    var clientId: String { get }
    /// The Mac this iPad paired with; discovery connects only to it.
    var pairedHostId: String? { get }
    var pairedHostName: String? { get }
    func token(for hostId: String) -> Data?
    func save(token: Data, hostId: String, hostName: String?)
    /// Forget the paired Mac; the next connection asks for a pairing code.
    func forget()
}

/// Pairing token in the Keychain; the paired Mac's id and name and this iPad's id in defaults.
final class KeychainPairingCredentials: PairingCredentials {
    private let service = "com.hoque.sidekey.pairing"
    private let defaults = UserDefaults.standard

    var clientId: String {
        if let id = defaults.string(forKey: "clientId") { return id }
        let id = UUID().uuidString
        defaults.set(id, forKey: "clientId")
        return id
    }

    var pairedHostId: String? { defaults.string(forKey: "pairedHostId") }
    var pairedHostName: String? { defaults.string(forKey: "pairedHostName") }

    func token(for hostId: String) -> Data? {
        var result: CFTypeRef?
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: hostId,
                                    kSecReturnData as String: true]
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    func save(token: Data, hostId: String, hostName: String?) {
        forget()
        let item: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: hostId,
                                   kSecValueData as String: token,
                                   kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else {
            // Without a stored token the iPad simply pairs again next time; say so loudly.
            print("[Pairing] Could not store the pairing token: \(status)")
            return
        }
        defaults.set(hostId, forKey: "pairedHostId")
        defaults.set(hostName, forKey: "pairedHostName")
    }

    func forget() {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                       kSecAttrService as String: service] as CFDictionary)
        defaults.removeObject(forKey: "pairedHostId")
        defaults.removeObject(forKey: "pairedHostName")
    }
}

/// Credentials kept in memory only, for tests.
final class InMemoryPairingCredentials: PairingCredentials {
    let clientId = "test-ipad"
    private(set) var pairedHostId: String?
    private(set) var pairedHostName: String?
    private var tokens: [String: Data] = [:]

    func token(for hostId: String) -> Data? { tokens[hostId] }

    func save(token: Data, hostId: String, hostName: String?) {
        tokens = [hostId: token]
        pairedHostId = hostId
        pairedHostName = hostName
    }

    func forget() {
        tokens.removeAll()
        pairedHostId = nil
        pairedHostName = nil
    }
}
