//
//  ApplicationGridViewModel.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import Combine
import AppKit

/// 应用网格视图模型
@MainActor
class ApplicationGridViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var applications: [ApplicationInfo] = []
    @Published var folders: [FolderInfo] = []
    @Published var isEditing: Bool = false
    @Published var selectedAppId: String?
    @Published var draggedAppId: String?
    @Published var gridSize: GridSize = .default
    @Published var currentPage: Int = 0
    
    // MARK: - Private Properties
    
    private let applicationScanner: ApplicationScanner
    private let folderManager: FolderManager
    private let settingsManager: SettingsManager
    private let eventBus: EventBus
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var appsForCurrentPage: [ApplicationInfo] {
        let startIndex = currentPage * gridSize.itemsPerPage
        let endIndex = min(startIndex + gridSize.itemsPerPage, applications.count)
        guard startIndex < applications.count else { return [] }
        return Array(applications[startIndex..<endIndex])
    }
    
    var pageCount: Int {
        return max(1, gridSize.pageCount(for: applications.count))
    }
    
    // MARK: - Initialization
    
    init(
        applicationScanner: ApplicationScanner,
        folderManager: FolderManager,
        settingsManager: SettingsManager,
        eventBus: EventBus
    ) {
        self.applicationScanner = applicationScanner
        self.folderManager = folderManager
        self.settingsManager = settingsManager
        self.eventBus = eventBus
        
        setupBindings()
        Task {
            await loadApplications()
            await loadFolders()
            await loadSettings()
        }
    }
    
    // MARK: - Public Methods
    
    /// 加载应用程序列表
    func loadApplications() async {
        applications = await applicationScanner.scanApplications()
    }
    
    /// 加载文件夹列表
    func loadFolders() async {
        folders = await folderManager.getAllFolders()
    }
    
    /// 加载设置
    func loadSettings() async {
        let settings = await settingsManager.getSettings()
        gridSize = GridSize(columns: settings.gridColumns, rows: settings.gridRows)
    }
    
    /// 切换编辑模式
    func toggleEditMode() {
        isEditing.toggle()
    }
    
    /// 进入编辑模式
    func enterEditMode() {
        isEditing = true
    }
    
    /// 退出编辑模式
    func exitEditMode() {
        isEditing = false
        selectedAppId = nil
    }
    
    /// 启动应用
    func launchApplication(_ app: ApplicationInfo) async {
        let config = NSWorkspace.OpenConfiguration()
        do {
            try await NSWorkspace.shared.openApplication(at: app.bundleURL, configuration: config)
            eventBus.publishApplicationLaunched(app.bundleIdentifier)
        } catch {
            print("Failed to launch application: \(error)")
        }
    }
    
    /// 删除应用
    func deleteApplication(_ app: ApplicationInfo) async throws {
        guard !app.isSystemApp else {
            throw GridError.cannotDeleteSystemApp
        }
        
        let fileURL = app.bundleURL
        try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
        
        // 从列表中移除
        applications.removeAll { $0.id == app.id }
        eventBus.publishApplicationRemoved(app.bundleIdentifier)
    }
    
    /// 开始拖拽
    func beginDrag(appId: String) {
        draggedAppId = appId
    }
    
    /// 结束拖拽
    func endDrag() {
        draggedAppId = nil
    }
    
    /// 移动应用到新位置
    func moveApp(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0,
              destinationIndex >= 0,
              sourceIndex < applications.count,
              destinationIndex < applications.count else { return }
        
        let app = applications.remove(at: sourceIndex)
        applications.insert(app, at: destinationIndex)
    }
    
    /// 创建文件夹
    func createFolder(with appIds: [String]) async {
        let name = FolderInfo.LocalizedString(
            english: "New Folder",
            chineseSimplified: nil
        )
        let folder = await folderManager.createFolder(name: name, applications: appIds)
        folders.append(folder)
        
        // 从应用列表中移除已加入文件夹的应用
        applications.removeAll { appIds.contains($0.bundleIdentifier) }
    }
    
    /// 选择应用
    func selectApp(_ appId: String) {
        selectedAppId = appId
    }
    
    /// 取消选择
    func deselectApp() {
        selectedAppId = nil
    }
    
    /// 切换页面
    func goToPage(_ page: Int) {
        guard page >= 0 && page < pageCount else { return }
        currentPage = page
        eventBus.publishPageChanged(page)
    }
    
    /// 下一页
    func nextPage() {
        if currentPage < pageCount - 1 {
            goToPage(currentPage + 1)
        }
    }
    
    /// 上一页
    func previousPage() {
        if currentPage > 0 {
            goToPage(currentPage - 1)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 监听编辑模式变化
        eventBus.editModeChanged
            .receive(on: DispatchQueue.main)
            .assign(to: &$isEditing)
        
        // 监听搜索查询变化
        eventBus.searchQueryChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] query in
                Task { @MainActor in
                    await self?.filterApplications(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func filterApplications(query: String) async {
        if query.isEmpty {
            await loadApplications()
        } else {
            let allApps = await applicationScanner.scanApplications()
            applications = allApps.filter { app in
                app.name.localizedCaseInsensitiveContains(query) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(query)
            }
        }
    }
}

// MARK: - Errors

enum GridError: Error, Sendable {
    case cannotDeleteSystemApp
    case invalidIndex
    case folderCreationFailed
}
