//
//  EventBus.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import Combine

/// 事件总线实现
final class EventBus: EventBusProtocol, @unchecked Sendable {
    
    // MARK: - Subjects
    
    private let applicationAddedSubject = PassthroughSubject<String, Never>()
    private let applicationRemovedSubject = PassthroughSubject<String, Never>()
    private let applicationLaunchedSubject = PassthroughSubject<String, Never>()
    private let editModeChangedSubject = PassthroughSubject<Bool, Never>()
    private let searchQueryChangedSubject = PassthroughSubject<String, Never>()
    private let pageChangedSubject = PassthroughSubject<Int, Never>()
    private let systemAppearanceChangedSubject = PassthroughSubject<AppSettings.AppearanceMode, Never>()
    private let accessibilitySettingsChangedSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Publishers
    
    var applicationAdded: AnyPublisher<String, Never> {
        applicationAddedSubject.eraseToAnyPublisher()
    }
    
    var applicationRemoved: AnyPublisher<String, Never> {
        applicationRemovedSubject.eraseToAnyPublisher()
    }
    
    var applicationLaunched: AnyPublisher<String, Never> {
        applicationLaunchedSubject.eraseToAnyPublisher()
    }
    
    var editModeChanged: AnyPublisher<Bool, Never> {
        editModeChangedSubject.eraseToAnyPublisher()
    }
    
    var searchQueryChanged: AnyPublisher<String, Never> {
        searchQueryChangedSubject.eraseToAnyPublisher()
    }
    
    var pageChanged: AnyPublisher<Int, Never> {
        pageChangedSubject.eraseToAnyPublisher()
    }
    
    var systemAppearanceChanged: AnyPublisher<AppSettings.AppearanceMode, Never> {
        systemAppearanceChangedSubject.eraseToAnyPublisher()
    }
    
    var accessibilitySettingsChanged: AnyPublisher<Void, Never> {
        accessibilitySettingsChangedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Publish Methods
    
    func publishApplicationAdded(_ appId: String) {
        applicationAddedSubject.send(appId)
    }
    
    func publishApplicationRemoved(_ appId: String) {
        applicationRemovedSubject.send(appId)
    }
    
    func publishApplicationLaunched(_ appId: String) {
        applicationLaunchedSubject.send(appId)
    }
    
    func publishEditModeChanged(_ isEditing: Bool) {
        editModeChangedSubject.send(isEditing)
    }
    
    func publishSearchQueryChanged(_ query: String) {
        searchQueryChangedSubject.send(query)
    }
    
    func publishPageChanged(_ page: Int) {
        pageChangedSubject.send(page)
    }
    
    func publishSystemAppearanceChanged(_ mode: AppSettings.AppearanceMode) {
        systemAppearanceChangedSubject.send(mode)
    }
    
    func publishAccessibilitySettingsChanged() {
        accessibilitySettingsChangedSubject.send(())
    }
}
