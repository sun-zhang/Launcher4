//
//  EventBusProtocol.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import Combine

/// 事件总线协议
protocol EventBusProtocol: Sendable {
    // 应用相关事件 (使用应用 ID)
    var applicationAdded: AnyPublisher<String, Never> { get }
    var applicationRemoved: AnyPublisher<String, Never> { get }
    var applicationLaunched: AnyPublisher<String, Never> { get }
    
    // UI 相关事件
    var editModeChanged: AnyPublisher<Bool, Never> { get }
    var searchQueryChanged: AnyPublisher<String, Never> { get }
    var pageChanged: AnyPublisher<Int, Never> { get }
    
    // 系统事件
    var systemAppearanceChanged: AnyPublisher<AppSettings.AppearanceMode, Never> { get }
    var accessibilitySettingsChanged: AnyPublisher<Void, Never> { get }
    
    // 发布方法
    func publishApplicationAdded(_ appId: String)
    func publishApplicationRemoved(_ appId: String)
    func publishApplicationLaunched(_ appId: String)
    func publishEditModeChanged(_ isEditing: Bool)
    func publishSearchQueryChanged(_ query: String)
    func publishPageChanged(_ page: Int)
    func publishSystemAppearanceChanged(_ mode: AppSettings.AppearanceMode)
    func publishAccessibilitySettingsChanged()
}
