//
//  SettingsManager.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 设置管理器 Actor
actor SettingsManager: SettingsManagerProtocol {
    
    // MARK: - Properties
    
    private var settings: AppSettings = .default
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "com.launcher4.settings"
    
    // MARK: - Initialization
    
    init() {
        if let loadedSettings = try? loadSettings() {
            settings = loadedSettings
        }
    }
    
    // MARK: - Public Methods
    
    func getSettings() -> AppSettings {
        return settings
    }
    
    func updateSettings(_ newSettings: AppSettings) throws {
        settings = newSettings
        try saveSettings()
    }
    
    func setIconSize(_ size: AppSettings.IconSize) throws {
        settings.iconSize = size
        try saveSettings()
    }
    
    func setGridColumns(_ columns: Int) throws {
        guard columns >= 3 && columns <= 12 else {
            throw SettingsError.invalidValue("Grid columns must be between 3 and 12")
        }
        settings.gridColumns = columns
        try saveSettings()
    }
    
    func setGridRows(_ rows: Int) throws {
        guard rows >= 3 && rows <= 10 else {
            throw SettingsError.invalidValue("Grid rows must be between 3 and 10")
        }
        settings.gridRows = rows
        try saveSettings()
    }
    
    func setShortcutKey(_ key: AppSettings.ShortcutKey) throws {
        settings.shortcutKey = key
        try saveSettings()
    }
    
    func setEnableGestures(_ enabled: Bool) throws {
        settings.enableGestures = enabled
        try saveSettings()
    }
    
    func setAppearanceMode(_ mode: AppSettings.AppearanceMode) throws {
        settings.appearanceMode = mode
        try saveSettings()
    }
    
    func setLanguage(_ language: AppSettings.AppLanguage) throws {
        settings.language = language
        try saveSettings()
    }
    
    func setPerformanceMode(_ mode: AppSettings.PerformanceMode) throws {
        settings.performanceMode = mode
        try saveSettings()
    }
    
    func saveSettings() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        userDefaults.set(data, forKey: settingsKey)
        userDefaults.synchronize()
    }
    
    func loadSettings() throws -> AppSettings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            return .default
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AppSettings.self, from: data)
    }
    
    func resetToDefaults() throws {
        settings = .default
        try saveSettings()
    }
    
    func exportSettings() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(settings)
    }
    
    func importSettings(_ data: Data) throws {
        let decoder = JSONDecoder()
        let importedSettings = try decoder.decode(AppSettings.self, from: data)
        settings = importedSettings
        try saveSettings()
    }
}

// MARK: - Errors

enum SettingsError: Error, Sendable {
    case invalidValue(String)
    case encodingError
    case decodingError
}
