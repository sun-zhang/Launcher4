//
//  PageNavigator.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import Combine

/// 页面导航器
@MainActor
class PageNavigator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 1
    @Published var isAnimating: Bool = false
    
    // MARK: - Private Properties
    
    private let gridSize: GridSize
    private let eventBus: EventBus
    private var totalItems: Int = 0
    
    // MARK: - Computed Properties
    
    var canGoToPrevious: Bool {
        return currentPage > 0
    }
    
    var canGoToNext: Bool {
        return currentPage < totalPages - 1
    }
    
    var pageIndicator: Int {
        return currentPage + 1
    }
    
    // MARK: - Initialization
    
    init(gridSize: GridSize = .default, eventBus: EventBus) {
        self.gridSize = gridSize
        self.eventBus = eventBus
    }
    
    // MARK: - Public Methods
    
    /// 更新总项目数
    func updateTotalItems(_ count: Int) {
        totalItems = count
        totalPages = max(1, (count + gridSize.itemsPerPage - 1) / gridSize.itemsPerPage)
        
        // 如果当前页超出范围，调整到最后一页
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
        }
    }
    
    /// 跳转到指定页
    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        guard !isAnimating else { return }
        
        isAnimating = true
        currentPage = page
        eventBus.publishPageChanged(page)
        
        // 动画完成后更新状态
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            isAnimating = false
        }
    }
    
    /// 下一页
    func nextPage() {
        if canGoToNext {
            goToPage(currentPage + 1)
        }
    }
    
    /// 上一页
    func previousPage() {
        if canGoToPrevious {
            goToPage(currentPage - 1)
        }
    }
    
    /// 第一页
    func firstPage() {
        goToPage(0)
    }
    
    /// 最后一页
    func lastPage() {
        goToPage(totalPages - 1)
    }
    
    /// 获取指定页的应用索引范围
    func getIndexPathRange(for page: Int) -> Range<Int> {
        let start = page * gridSize.itemsPerPage
        let end = min(start + gridSize.itemsPerPage, totalItems)
        return start..<end
    }
    
    /// 获取当前页的应用索引范围
    func currentIndexPathRange() -> Range<Int> {
        return getIndexPathRange(for: currentPage)
    }
    
    /// 计算指定应用所在页
    func pageForItem(at index: Int) -> Int {
        return index / gridSize.itemsPerPage
    }
    
    /// 跳转到包含指定应用的页
    func goToPageContaining(itemAt index: Int) {
        let page = pageForItem(at: index)
        goToPage(page)
    }
}
