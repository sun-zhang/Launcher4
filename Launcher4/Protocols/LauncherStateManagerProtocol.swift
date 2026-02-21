//
//  LauncherStateManagerProtocol.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// Launcher 状态管理器协议
protocol LauncherStateManagerProtocol: Sendable {
    /// 是否可见
    var isVisible: Bool { get async }
    
    /// 动画是否进行中
    var animationInProgress: Bool { get async }
    
    /// 显示 Launcher
    func showLauncher() async
    
    /// 隐藏 Launcher
    func hideLauncher() async
    
    /// 切换 Launcher 可见性
    func toggleLauncher() async
    
    /// 获取窗口框架
    func getWindowFrame() async -> CGRect
    
    /// 设置窗口框架
    func setWindowFrame(_ frame: CGRect) async
    
    /// 更新背景模糊强度
    func updateBackgroundBlur(_ intensity: Double) async
}
