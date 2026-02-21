//
//  PerformanceMode.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 性能模式管理
enum PerformanceMode: String, Codable, Sendable {
    case swiftUI
    case coreAnimation
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .swiftUI:
            return NSLocalizedString("Standard", comment: "Standard performance mode")
        case .coreAnimation:
            return NSLocalizedString("High Performance", comment: "High performance mode with Core Animation")
        }
    }
    
    /// 描述
    var description: String {
        switch self {
        case .swiftUI:
            return NSLocalizedString("Standard mode with smooth animations", comment: "")
        case .coreAnimation:
            return NSLocalizedString("Optimized for 120Hz ProMotion displays", comment: "")
        }
    }
    
    /// 是否需要重启
    var requiresRestart: Bool {
        return false // Swift 切换不需要重启
    }
}
