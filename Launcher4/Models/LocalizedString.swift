//
//  LocalizedString.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 通用本地化字符串
struct LocalizedString: Codable, Equatable, Hashable, Sendable {
    let english: String
    let chineseSimplified: String?
    let chineseTraditional: String?
    let japanese: String?
    let korean: String?
    
    /// 获取当前语言的字符串
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
    
    /// 创建仅英文的本地化字符串
    static func english(_ text: String) -> LocalizedString {
        LocalizedString(
            english: text,
            chineseSimplified: nil,
            chineseTraditional: nil,
            japanese: nil,
            korean: nil
        )
    }
    
    /// 创建中英文本地化字符串
    static func englishAndChinese(english: String, simplified: String) -> LocalizedString {
        LocalizedString(
            english: english,
            chineseSimplified: simplified,
            chineseTraditional: nil,
            japanese: nil,
            korean: nil
        )
    }
}
