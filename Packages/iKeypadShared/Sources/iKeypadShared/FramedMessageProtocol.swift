import Foundation
import Network

public final class FramedMessageProtocol {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    /// Pack a message into length-prefixed bytes (4-byte big endian header + JSON body)
    public static func encode(_ message: DeckMessage) throws -> Data {
        let payload = try encoder.encode(message)
        var length = UInt32(payload.count).bigEndian
        var data = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
        data.append(payload)
        return data
    }

    /// Read one framed message from the front of a streaming buffer.
    ///
    /// A complete frame is removed from ``buffer`` whether or not its JSON decodes.
    ///
    /// :param buffer: Bytes received so far; consumed frames are removed in place.
    /// :returns: The decoded message, or ``nil`` when the frame is incomplete (buffer left
    ///     untouched) or its JSON could not be decoded (frame dropped and logged).
    public static func decode(from buffer: inout Data) -> DeckMessage? {
        guard buffer.count >= 4 else { return nil }

        let length: UInt32 = buffer.prefix(4).withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self).bigEndian
        }
        let totalFrameSize = 4 + Int(length)

        guard buffer.count >= totalFrameSize else { return nil }

        let payload = buffer.subdata(in: 4..<totalFrameSize)
        buffer.removeSubrange(0..<totalFrameSize)

        do {
            return try decoder.decode(DeckMessage.self, from: payload)
        } catch {
            // A version mismatch between Mac and iPad must not vanish silently.
            print("[Protocol] Dropped undecodable \(length)-byte message: \(error)")
            return nil
        }
    }
}
