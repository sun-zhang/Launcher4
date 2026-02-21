//
//  ApplicationScannerProtocol.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 应用扫描器协议
protocol ApplicationScannerProtocol: Sendable {
    /// 扫描所有应用程序
    func scanApplications() async -> [ApplicationInfo]
    
    /// 启动文件系统监控
    func startMonitoring() async
    
    /// 停止文件系统监控
    func stopMonitoring() async
    
    /// 应用变更回调
    var onApplicationsChanged: (@Sendable (Set<ApplicationChange>) -> Void)? { get set }
}

/// 应用变更类型
enum ApplicationChange: Sendable, Hashable {
    case added(String) // 应用 ID
    case removed(String) // 应用 ID
    case updated(String) // 应用 ID
}
