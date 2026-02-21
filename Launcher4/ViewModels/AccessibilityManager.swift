//
//  AccessibilityManager.swift
//  Launcher4
//
//  Created by Sisyphus on 2926/2/21.
//

import Foundation
import AppKit
import Combine

/// 可访问性管理器
@MainActor
class AccessibilityManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isVoiceOverRunning: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    @Published var isHighContrastEnabled: Bool = false
    @Published var isIncreaseContrastEnabled: Bool = false
    @Published var focusedAppIndex: Int?
    
    // MARK: - Private Properties
    
    private let eventBus: EventBus
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(eventBus: EventBus) {
        self.eventBus = eventBus
        
        checkAccessibilitySettings()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// 检查可访问性设置
    func checkAccessibilitySettings() {
        isVoiceOverRunning = NSWorkspace.shared.isVoiceOverEnabled
        // 使用不同的 API 检测减少动画和对比度设置
        isReduceMotionEnabled = false // 需要通过其他方式检测
        isHighContrastEnabled = NSWorkspace.shared.isSwitchControlEnabled
        isIncreaseContrastEnabled = false // 需要通过其他方式检测
    }
    
    /// 设置 VoiceOver 标签
    func setAccessibilityLabel(for view: NSView, label: String) {
        view.setAccessibilityLabel(label)
    }
    
    /// 设置 VoiceOver 帮助
    func setAccessibilityHelp(for view: NSView, help: String) {
        view.setAccessibilityHelp(help)
    }
    
    /// 设置 VoiceOver 描述
    func setAccessibilityDescription(for view: NSView, description: String) {
        view.setAccessibilityValueDescription(description)
    }
    
    /// 标记为按钮
    func setAsAccessibilityButton(_ view: NSView) {
        view.setAccessibilityRole(.button)
    }
    
    /// 标记为图像
    func setAsAccessibilityImage(_ view: NSView, description: String) {
        view.setAccessibilityRole(.image)
        view.setAccessibilityLabel(description)
    }
    
    /// 设置焦点
    func setFocus(to index: Int) {
        focusedAppIndex = index
    }
    
    /// 清除焦点
    func clearFocus() {
        focusedAppIndex = nil
    }
    
    /// 移动焦点到下一个应用
    func moveFocusForward(totalApps: Int) {
        if let current = focusedAppIndex {
            focusedAppIndex = (current + 1) % totalApps
        } else {
            focusedAppIndex = 0
        }
    }
    
    /// 移动焦点到上一个应用
    func moveFocusBackward(totalApps: Int) {
        if let current = focusedAppIndex {
            focusedAppIndex = (current - 1 + totalApps) % totalApps
        } else {
            focusedAppIndex = totalApps - 1
        }
    }
    
    /// 获取当前动画持续时间
    func getAnimationDuration() -> Double {
        return isReduceMotionEnabled ? 0.0 : 0.3
    }
    
    /// 获取当前动画曲线
    func getAnimationCurve() -> CAMediaTimingFunction {
        return isReduceMotionEnabled 
            ? CAMediaTimingFunction(name: .linear)
            : CAMediaTimingFunction(name: .easeInEaseOut)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // 监听 VoiceOver 状态变化
        NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkAccessibilitySettings()
                self?.eventBus.publishAccessibilitySettingsChanged()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Accessibility Labels

extension AccessibilityManager {
    
    /// 应用图标标签
    func appIconLabel(name: String, isRunning: Bool) -> String {
        let status = isRunning ? "Running" : "Not running"
        return "\(name), \(status)"
    }
    
    /// 文件夹标签
    func folderLabel(name: String, appCount: Int) -> String {
        return "\(name), folder with \(appCount) applications"
    }
    
    /// 页面指示器标签
    func pageIndicatorLabel(current: Int, total: Int) -> String {
        return "Page \(current + 1) of \(total)"
    }
    
    /// 编辑模式标签
    func editModeLabel(isEditing: Bool) -> String {
        return isEditing ? "Edit mode on" : "Edit mode off"
    }
    
    /// 搜索框标签
    func searchFieldLabel() -> String {
        return "Search applications"
    }
}
