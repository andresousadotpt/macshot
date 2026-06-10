import Foundation

public actor SettingsStore {
    public static let defaultSupportDirectoryName = "Macshot"
    private static let settingsFileName = "settings.json"

    private let fileURL: URL
    private var settings: AppSettings

    public init(supportDirectoryName: String = SettingsStore.defaultSupportDirectoryName) {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let directory = appSupport.appendingPathComponent(supportDirectoryName, isDirectory: true)
        self.fileURL = directory.appendingPathComponent(Self.settingsFileName)
        self.settings = Self.load(from: fileURL) ?? .default
    }

    public func current() -> AppSettings {
        settings
    }

    public func save(_ newSettings: AppSettings) throws {
        settings = newSettings
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(newSettings)
        let tempURL = directory.appendingPathComponent(".settings-\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: .atomic)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
    }

    private static func load(from url: URL) -> AppSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }
}
