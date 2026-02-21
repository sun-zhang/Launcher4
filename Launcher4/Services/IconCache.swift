//
//  IconCache.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import AppKit

/// 图标缓存 Actor
actor IconCache: IconCacheProtocol {
    
    // MARK: - Properties
    
    private var memoryCache: NSCache<NSString, NSImage>
    private var cacheStats = CacheStats(iconCount: 0, memoryUsage: 0, hitRate: 0)
    private var hitCount: Int = 0
    private var missCount: Int = 0
    
    private let maxMemoryUsage: Int64 = 50 * 1024 * 1024 // 50MB
    private let maxIconCount: Int = 500
    
    // MARK: - Initialization
    
    init() {
        memoryCache = NSCache()
        memoryCache.totalCostLimit = Int(maxMemoryUsage)
        memoryCache.countLimit = maxIconCount
    }
    
    // MARK: - Public Methods
    
    /// 获取图标
    func getIcon(for appId: String, url: URL) -> NSImage? {
        let key = appId as NSString
        
        // 检查内存缓存
        if let cachedImage = memoryCache.object(forKey: key) {
            hitCount += 1
            updateStats()
            return cachedImage
        }
        
        missCount += 1
        
        // 从文件加载图标
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        // 缓存图标
        setIcon(icon, for: appId)
        updateStats()
        return icon
    }
    
    /// 设置图标
    func setIcon(_ image: NSImage, for appId: String) {
        let key = appId as NSString
        
        // 计算图像大小作为成本
        let cost = estimateImageSize(image)
        memoryCache.setObject(image, forKey: key, cost: cost)
        
        updateStats()
    }
    
    /// 清除缓存
    func clearCache() {
        memoryCache.removeAllObjects()
        hitCount = 0
        missCount = 0
        updateStats()
    }
    
    /// 预加载图标
    func preloadIcons(for apps: [ApplicationInfo]) {
        for app in apps.prefix(50) { // 预加载前 50 个应用
            Task {
                _ = getIcon(for: app.bundleIdentifier, url: app.bundleURL)
            }
        }
    }
    
    /// 获取缓存统计
    func getCacheStats() -> CacheStats {
        return cacheStats
    }
    
    // MARK: - Private Methods
    
    private func estimateImageSize(_ image: NSImage) -> Int {
        guard let rep = image.representations.first else {
            return 1024 // 默认 1KB
        }
        return Int(rep.pixelsWide * rep.pixelsHigh * 4) // RGBA
    }
    
    private func updateStats() {
        let total = hitCount + missCount
        let rate = total > 0 ? Double(hitCount) / Double(total) : 0
        
        cacheStats = CacheStats(
            iconCount: memoryCacheCount(),
            memoryUsage: estimateTotalMemoryUsage(),
            hitRate: rate
        )
    }
    
    private func memoryCacheCount() -> Int {
        // NSCache 没有直接获取数量的方法，使用估计值
        return missCount // 粗略估计
    }
    
    private func estimateTotalMemoryUsage() -> Int64 {
        return Int64(missCount * 1024 * 64) // 粗略估计
    }
}
