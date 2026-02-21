//
//  AppSettings.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 应用设置模型
struct AppSettings: Codable, Equatable, Sendable {
    // 图标设置
    var iconSize: IconSize = .medium
    
    // 网格设置
    var gridColumns: Int = 7
    var gridRows: Int = 5
    
    // 快捷键设置
    var shortcutKey: ShortcutKey = .f4
    
    // 手势设置
    var enableGestures: Bool = true
    
    // 外观设置
    var appearanceMode: AppearanceMode = .auto
    var enableAnimations: Bool = true
    var reduceMotion: Bool = false
    var highContrast: Bool = false
    
    // 语言设置
    var language: AppLanguage = .system
    
    // 背景设置
    var backgroundBlurIntensity: Double = 0.7
    
    // 搜索历史
    var searchHistoryEnabled: Bool = true
    
    // 性能模式
    var performanceMode: PerformanceMode = .swiftUI
    
    // 悬停效果
    var hoverMagnificationEnabled: Bool = true
    var hoverMagnificationScale: Double = 1.1
    
    // 按压效果
    var activePressEnabled: Bool = true
    var activePressScale: Double = 0.9
    
    // 编辑模式
    var lockLayout: Bool = false
    
    // 图标大小枚举
    enum IconSize: String, Codable, Sendable {
        case small
        case medium
        case large
    }
    
    // 快捷键枚举
    enum ShortcutKey: String, Codable, Sendable {
        case f4
        case fnF4
        case custom
    }
    
    // 外观模式枚举
    enum AppearanceMode: String, Codable, Sendable {
        case light
        case dark
        case auto
    }
    
    // 语言枚举
    enum AppLanguage: String, Codable, Sendable {
        case system
        case english
        case chineseSimplified
        case chineseTraditional
        case japanese
        case korean
    }
    
    // 性能模式枚举
    enum PerformanceMode: String, Codable, Sendable {
        case swiftUI
        case coreAnimation
    }
    
    /// 默认设置
    static let `default` = AppSettings()
}
