import Foundation

public struct AppSettings: Codable, Sendable, Equatable {
    public var dimOpacity: Double
    public var gifFPS: Int
    public var maxRecordingDuration: TimeInterval
    public var screenshotHotkey: HotkeyBinding
    public var gifHotkey: HotkeyBinding
    public var hasCompletedPermissionOnboarding: Bool
    public var launchAtLogin: Bool

    public init(
        dimOpacity: Double = 0.35,
        gifFPS: Int = 15,
        maxRecordingDuration: TimeInterval = 30,
        screenshotHotkey: HotkeyBinding = .defaultScreenshot,
        gifHotkey: HotkeyBinding = .defaultGIF,
        hasCompletedPermissionOnboarding: Bool = false,
        launchAtLogin: Bool = true
    ) {
        self.dimOpacity = dimOpacity
        self.gifFPS = gifFPS
        self.maxRecordingDuration = maxRecordingDuration
        self.screenshotHotkey = screenshotHotkey
        self.gifHotkey = gifHotkey
        self.hasCompletedPermissionOnboarding = hasCompletedPermissionOnboarding
        self.launchAtLogin = launchAtLogin
    }

    public static let `default` = AppSettings()

    public var hotkeysConflict: Bool {
        screenshotHotkey == gifHotkey
    }

    enum CodingKeys: String, CodingKey {
        case dimOpacity, gifFPS, maxRecordingDuration, screenshotHotkey, gifHotkey, hasCompletedPermissionOnboarding, launchAtLogin
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dimOpacity = try container.decodeIfPresent(Double.self, forKey: .dimOpacity) ?? 0.35
        gifFPS = try container.decodeIfPresent(Int.self, forKey: .gifFPS) ?? 15
        maxRecordingDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .maxRecordingDuration) ?? 30
        screenshotHotkey = try container.decodeIfPresent(HotkeyBinding.self, forKey: .screenshotHotkey) ?? .defaultScreenshot
        gifHotkey = try container.decodeIfPresent(HotkeyBinding.self, forKey: .gifHotkey) ?? .defaultGIF
        hasCompletedPermissionOnboarding = try container.decodeIfPresent(
            Bool.self,
            forKey: .hasCompletedPermissionOnboarding
        ) ?? false
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? true
    }
}
