//
//  LauncherStateManager.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import AppKit

/// Launcher 状态管理器 Actor
actor LauncherStateManager: LauncherStateManagerProtocol {
    
    // MARK: - Properties
    
    private(set) var isVisible: Bool = false
    private(set) var animationInProgress: Bool = false
    
    private var windowFrame: CGRect = .zero
    private var blurIntensity: Double = 0.7
    
    // MARK: - Public Methods
    
    /// 显示 Launcher
    func showLauncher() {
        guard !animationInProgress else { return }
        
        animationInProgress = true
        isVisible = true
        
        // 动画完成后更新状态
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            await setAnimationInProgress(false)
        }
    }
    
    /// 隐藏 Launcher
    func hideLauncher() {
        guard !animationInProgress else { return }
        
        animationInProgress = true
        
        // 动画完成后更新状态
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            await setIsVisible(false)
            await setAnimationInProgress(false)
        }
    }
    
    /// 切换 Launcher 可见性
    func toggleLauncher() {
        if isVisible {
            hideLauncher()
        } else {
            showLauncher()
        }
    }
    
    /// 获取窗口框架
    func getWindowFrame() -> CGRect {
        if windowFrame == .zero {
            // 计算默认窗口框架（居中、全屏尺寸）
            let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
            return screen
        }
        return windowFrame
    }
    
    /// 设置窗口框架
    func setWindowFrame(_ frame: CGRect) {
        windowFrame = frame
    }
    
    /// 更新背景模糊强度
    func updateBackgroundBlur(_ intensity: Double) {
        blurIntensity = max(0, min(1, intensity))
    }
    
    // MARK: - Private Methods
    
    private func setAnimationInProgress(_ value: Bool) {
        animationInProgress = value
    }
    
    private func setIsVisible(_ value: Bool) {
        isVisible = value
    }
}
