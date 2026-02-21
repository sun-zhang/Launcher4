//
//  IconCacheProtocol.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import AppKit

/// 图标缓存协议
protocol IconCacheProtocol: Sendable {
    /// 获取图标
    func getIcon(for appId: String, url: URL) async -> NSImage?
    
    /// 设置图标
    func setIcon(_ image: NSImage, for appId: String) async
    
    /// 清除缓存
    func clearCache() async
    
    /// 预加载图标
    func preloadIcons(for apps: [ApplicationInfo]) async
    
    /// 获取缓存统计
    func getCacheStats() async -> CacheStats
}

/// 缓存统计
struct CacheStats: Sendable {
    let iconCount: Int
    let memoryUsage: Int64
    let hitRate: Double
}
