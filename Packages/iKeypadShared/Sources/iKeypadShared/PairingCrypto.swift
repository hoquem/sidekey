import Foundation
import CryptoKit
import Security

/// Cryptographic helpers for pairing an iPad with a Mac.
///
/// Pairing happens once: the Mac shows a short-lived 6-digit code, the iPad sends it, and the Mac
/// returns a random 32-byte token. On every later connection the Mac sends a fresh nonce and the
/// iPad answers with ``proof(token:nonce:)``, so the token itself never crosses the network again.
/// Both sides keep the token in their Keychain.
public enum PairingCrypto {
    public enum Failure: Error {
        case randomGenerationFailed(OSStatus)
    }

    /// ``count`` cryptographically secure random bytes.
    public static func randomBytes(_ count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else { throw Failure.randomGenerationFailed(status) }
        return Data(bytes)
    }

    /// A uniformly random 6-digit code such as "042917".
    public static func pairingCode() throws -> String {
        // Rejection sampling keeps every code equally likely.
        while true {
            let value = try randomBytes(4).withUnsafeBytes { $0.load(as: UInt32.self) }
            if value < UInt32.max - (UInt32.max % 1_000_000) {
                return String(format: "%06u", value % 1_000_000)
            }
        }
    }

    /// HMAC-SHA256 of ``nonce`` keyed with the pairing ``token``.
    public static func proof(token: Data, nonce: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: nonce, using: SymmetricKey(data: token)))
    }

    /// Whether ``proof`` was made with ``token`` for ``nonce``, compared in constant time.
    public static func verify(proof: Data, token: Data, nonce: Data) -> Bool {
        HMAC<SHA256>.isValidAuthenticationCode(proof, authenticating: nonce, using: SymmetricKey(data: token))
    }
}
