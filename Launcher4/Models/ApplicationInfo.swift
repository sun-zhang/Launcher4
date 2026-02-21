//
//  ApplicationInfo.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 应用程序信息模型
struct ApplicationInfo: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let bundleURL: URL
    let iconURL: URL?
    let isSystemApp: Bool
    let installDate: Date
    let lastLaunchDate: Date?
    let launchCount: Int
    let localizedName: LocalizedString
    
    // 计算属性
    var displayName: String { localizedName.currentLanguage }
    var isRunning: Bool = false
    var canBeDeleted: Bool { !isSystemApp }
    
    /// 本地化字符串支持
    struct LocalizedString: Codable, Equatable, Hashable, Sendable {
        let english: String
        let chineseSimplified: String?
        let chineseTraditional: String?
        let japanese: String?
        let korean: String?
        
        var currentLanguage: String {
            let locale = Locale.current
            if locale.identifier.contains("zh-Hans"), let chinese = chineseSimplified {
                return chinese
            } else if locale.identifier.contains("zh-Hant"), let chinese = chineseTraditional {
                return chinese
            } else if locale.identifier.contains("ja"), let japanese = japanese {
                return japanese
            } else if locale.identifier.contains("ko"), let korean = korean {
                return korean
            }
            return english
        }
        
        static func english(_ text: String) -> LocalizedString {
            LocalizedString(
                english: text,
                chineseSimplified: nil,
                chineseTraditional: nil,
                japanese: nil,
                korean: nil
            )
        }
    }
}
