//
//  SearchViewModel.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import Combine

/// 搜索视图模型
@MainActor
class SearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var searchQuery: String = ""
    @Published var searchResults: [ApplicationInfo] = []
    @Published var isSearching: Bool = false
    @Published var searchHistory: [String] = []
    @Published var noResults: Bool = false
    
    // MARK: - Private Properties
    
    private let applicationScanner: ApplicationScanner
    private let eventBus: EventBus
    private var allApplications: [ApplicationInfo] = []
    private var searchDebounceTask: Task<Void, Never>?
    private let debounceDuration: UInt64 = 50_000_000 // 50ms
    
    // MARK: - Initialization
    
    init(applicationScanner: ApplicationScanner, eventBus: EventBus) {
        self.applicationScanner = applicationScanner
        self.eventBus = eventBus
        
        Task {
            await loadApplications()
        }
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 加载应用程序列表
    func loadApplications() async {
        allApplications = await applicationScanner.scanApplications()
    }
    
    /// 搜索应用
    func search(_ query: String) {
        // 取消之前的搜索任务
        searchDebounceTask?.cancel()
        
        // 创建新的搜索任务（带防抖）
        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.debounceDuration ?? 50_000_000)
            
            guard !Task.isCancelled else { return }
            
            await self?.performSearch(query)
        }
    }
    
    /// 清空搜索
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        noResults = false
        isSearching = false
    }
    
    /// 添加到搜索历史
    func addToHistory(_ query: String) {
        guard !query.isEmpty else { return }
        
        // 移除重复项
        searchHistory.removeAll { $0 == query }
        
        // 添加到历史
        searchHistory.insert(query, at: 0)
        
        // 限制历史记录数量
        if searchHistory.count > 10 {
            searchHistory.removeLast()
        }
    }
    
    /// 清空搜索历史
    func clearHistory() {
        searchHistory = []
    }
    
    /// 从历史中选择搜索
    func selectFromHistory(_ query: String) {
        searchQuery = query
        search(query)
    }
    
    /// 获取搜索结果数量
    var resultCount: Int {
        return searchResults.count
    }
    
    /// 是否有搜索结果
    var hasResults: Bool {
        return !searchResults.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        $searchQuery
            .removeDuplicates()
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.clearSearch()
                } else {
                    self?.search(query)
                }
            }
    }
    
    private func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
                noResults = false
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        let results = allApplications.filter { app in
            let nameMatch = app.name.localizedCaseInsensitiveContains(query)
            let bundleIdMatch = app.bundleIdentifier.localizedCaseInsensitiveContains(query)
            let localizedNameMatch = app.localizedName.currentLanguage.localizedCaseInsensitiveContains(query)
            
            return nameMatch || bundleIdMatch || localizedNameMatch
        }
        
        // 按匹配度排序
        let sortedResults = results.sorted { app1, app2 in
            let score1 = matchScore(query: query, app: app1)
            let score2 = matchScore(query: query, app: app2)
            return score1 > score2
        }
        
        await MainActor.run {
            searchResults = sortedResults
            noResults = sortedResults.isEmpty
            isSearching = false
        }
        
        // 发布搜索事件
        eventBus.publishSearchQueryChanged(query)
    }
    
    private func matchScore(query: String, app: ApplicationInfo) -> Int {
        var score = 0
        
        // 名称完全匹配
        if app.name.lowercased() == query.lowercased() {
            score += 100
        }
        // 名称开头匹配
        else if app.name.lowercased().hasPrefix(query.lowercased()) {
            score += 80
        }
        // 名称包含
        else if app.name.localizedCaseInsensitiveContains(query) {
            score += 60
        }
        
        // Bundle ID 匹配
        if app.bundleIdentifier.localizedCaseInsensitiveContains(query) {
            score += 30
        }
        
        // 本地化名称匹配
        let localizedName = app.localizedName.currentLanguage
        if localizedName.localizedCaseInsensitiveContains(query) {
            score += 50
        }
        
        return score
    }
}
