//
//  SettingsManagerProtocol.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 设置管理器协议
protocol SettingsManagerProtocol: Sendable {
    /// 获取完整设置
    func getSettings() async -> AppSettings
    
    /// 更新设置
    func updateSettings(_ settings: AppSettings) async throws
    
    /// 设置图标大小
    func setIconSize(_ size: AppSettings.IconSize) async throws
    
    /// 设置网格列数
    func setGridColumns(_ columns: Int) async throws
    
    /// 设置网格行数
    func setGridRows(_ rows: Int) async throws
    
    /// 设置快捷键
    func setShortcutKey(_ key: AppSettings.ShortcutKey) async throws
    
    /// 设置启用手势
    func setEnableGestures(_ enabled: Bool) async throws
    
    /// 设置外观模式
    func setAppearanceMode(_ mode: AppSettings.AppearanceMode) async throws
    
    /// 设置语言
    func setLanguage(_ language: AppSettings.AppLanguage) async throws
    
    /// 设置性能模式
    func setPerformanceMode(_ mode: AppSettings.PerformanceMode) async throws
    
    /// 保存设置
    func saveSettings() async throws
    
    /// 加载设置
    func loadSettings() async throws -> AppSettings
    
    /// 重置为默认设置
    func resetToDefaults() async throws
    
    /// 导出设置
    func exportSettings() async throws -> Data
    
    /// 导入设置
    func importSettings(_ data: Data) async throws
}
