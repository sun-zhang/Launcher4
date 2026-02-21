//
//  FolderInfo.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 文件夹信息模型
struct FolderInfo: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: LocalizedString
    var applications: [String] // 应用 ID 列表
    let creationDate: Date
    var modifiedDate: Date
    var iconPreview: Data?
    var colorTheme: FolderColorTheme
    
    var applicationCount: Int { applications.count }
    var isEmpty: Bool { applications.isEmpty }
    
    /// 文件夹颜色主题
    enum FolderColorTheme: String, Codable, Sendable {
        case blue
        case green
        case orange
        case purple
        case pink
        case gray
    }
    
    /// 本地化字符串
    struct LocalizedString: Codable, Equatable, Hashable, Sendable {
        let english: String
        let chineseSimplified: String?
        
        var currentLanguage: String {
            let locale = Locale.current
            if locale.identifier.contains("zh-Hans"), let chinese = chineseSimplified {
                return chinese
            }
            return english
        }
        
        static func english(_ text: String) -> LocalizedString {
            LocalizedString(english: text, chineseSimplified: nil)
        }
    }
}
