import Foundation
import iKeypadShared

/// A user layout file Sidekey refused to load, and why, for showing to the user.
struct LayoutFileError: Equatable {
    let fileName: String
    let reason: String
}

/// The user's layout files, one ``LayoutCustomisation`` per ``<layoutId>.json`` in ``directory``.
/// The app uses ``defaultDirectory``; tests pass a temporary folder so they never touch the
/// user's real layouts.
struct UserLayoutStore {
    let directory: URL

    /// ``~/Library/Application Support/Sidekey/Layouts``.
    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sidekey/Layouts", isDirectory: true)
    }

    /// Read and validate every ``.json`` file in the folder, in file name order. A file that fails
    /// to decode or validate is reported and skipped whole; it is never partly loaded.
    ///
    /// :param builtIns: Sidekey's built-in layouts, for ``LayoutValidator``.
    /// :returns: The files that are safe to install, and the ones that were refused.
    func loadAll(builtIns: [DeckProfile]) -> (customisations: [LayoutCustomisation], errors: [LayoutFileError]) {
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        } catch CocoaError.fileReadNoSuchFile {
            return ([], [])
        } catch {
            return ([], [LayoutFileError(fileName: directory.lastPathComponent, reason: "Cannot read the folder: \(error.localizedDescription)")])
        }

        var customisations: [LayoutCustomisation] = []
        var errors: [LayoutFileError] = []
        for file in files.filter({ $0.pathExtension == "json" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let name = file.lastPathComponent
            let customisation: LayoutCustomisation
            do {
                customisation = try JSONDecoder().decode(LayoutCustomisation.self, from: Data(contentsOf: file))
            } catch {
                errors.append(LayoutFileError(fileName: name, reason: "Not a valid layout file: \(error.localizedDescription)"))
                continue
            }
            if let problem = LayoutValidator.problem(in: customisation, fileName: name, builtIns: builtIns) {
                errors.append(LayoutFileError(fileName: name, reason: problem))
            } else {
                customisations.append(customisation)
            }
        }
        return (customisations, errors)
    }

    /// Write ``customisation`` to ``<layoutId>.json``, replacing any earlier version atomically.
    ///
    /// :raises LayoutStoreError.invalid: when the validator rejects it, so the editor can never
    ///     write a file the next launch would refuse.
    func save(_ customisation: LayoutCustomisation) throws {
        let name = "\(customisation.layoutId).json"
        if let problem = LayoutValidator.problem(in: customisation, fileName: name, builtIns: DefaultProfiles.allDefaultProfiles()) {
            throw LayoutStoreError.invalid(problem)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(customisation).write(to: directory.appendingPathComponent(name), options: .atomic)
    }

    /// Remove ``<layoutId>.json``. Throws if there is no such file.
    /// :raises LayoutStoreError.invalid: when ``layoutId`` could escape the folder.
    func delete(layoutId: String) throws {
        guard LayoutValidator.isSafeLayoutId(layoutId) else {
            throw LayoutStoreError.invalid("Invalid layoutId \"\(layoutId)\".")
        }
        try FileManager.default.removeItem(at: directory.appendingPathComponent("\(layoutId).json"))
    }
}

enum LayoutStoreError: LocalizedError, Equatable {
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .invalid(let reason): return reason
        }
    }
}

extension UserLayoutStore {
    /// The store the running app reads and the editor writes.
    static let app = UserLayoutStore(directory: defaultDirectory)
}
