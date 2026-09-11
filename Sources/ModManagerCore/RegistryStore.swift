import Foundation

public actor RegistryStore {
    public let url: URL
    private var state: RegistryState

    public init(url: URL) {
        self.url = url
        if let data = try? Data(contentsOf: url), let decoded = try? JSONDecoder.registry.decode(RegistryState.self, from: data) {
            self.state = decoded
        } else {
            self.state = RegistryState()
        }
    }

    public func snapshot() -> RegistryState { state }

    public func replace(with newState: RegistryState) throws {
        state = newState
        try persist()
    }

    public func upsert(_ mod: ModRecord) throws {
        if let index = state.mods.firstIndex(where: { $0.id == mod.id }) {
            state.mods[index] = mod
        } else {
            state.mods.append(mod)
        }
        try persist()
    }

    public func remove(id: UUID) throws {
        state.mods.removeAll { $0.id == id }
        try persist()
    }

    public func recordInspection(gameURL: URL, fingerprint: BinaryFingerprint?) throws {
        state.gameAppURL = gameURL
        state.lastSeenFingerprint = fingerprint
        try persist()
    }

    private func persist() throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder.registry.encode(state)
        let temporary = directory.appendingPathComponent(".registry-\(UUID().uuidString).tmp")
        try data.write(to: temporary, options: [.atomic])
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary, backupItemName: nil, options: [])
        } else {
            try FileManager.default.moveItem(at: temporary, to: url)
        }
    }
}

private extension JSONEncoder {
    static var registry: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }
}

private extension JSONDecoder {
    static var registry: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }
}
