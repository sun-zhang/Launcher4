# 设计文档

## 概述

macOS Launcher 是一个独立的 macOS 应用程序，提供类似 macOS Launchpad 的网格化应用管理界面。该应用旨在为用户提供优雅、高效的应用程序访问体验，通过直观的图形界面帮助用户浏览、搜索和管理已安装的应用程序。

### 设计目标

1. **用户体验优先**: 提供流畅、直观的操作体验，符合 macOS 设计规范
2. **性能优化**: 确保快速响应，即使在大量应用情况下也能保持流畅
3. **系统集成**: 与 macOS 系统功能（Dock、Mission Control、触控板手势）深度集成
4. **可扩展性**: 支持未来功能扩展，同时保持核心架构稳定
5. **可维护性**: 采用模块化设计，便于测试和维护

### 技术栈选择

- **UI 框架**: SwiftUI - 符合 macOS 设计规范，支持深色/浅色模式
- **应用发现**: Launch Services API - 获取系统应用信息
- **文件监控**: File System Events API - 实时监控应用安装/卸载
- **数据存储**: Core Data + UserDefaults - 持久化用户布局和设置
- **动画引擎**: SwiftUI 内置动画系统

## 架构

### 整体架构

macOS Launcher 采用分层架构设计，分为以下四层：

```
┌─────────────────────────────────────┐
│           Presentation Layer         │
│  (Views, ViewModels, Animations)    │
├─────────────────────────────────────┤
│           Business Logic Layer       │
│   (Use Cases, Services, Managers)   │
├─────────────────────────────────────┤
│           Data Access Layer          │
│  (Repositories, Data Models, APIs)  │
├─────────────────────────────────────┤
│           System Integration Layer   │
│  (File System, Launch Services, UI) │
└─────────────────────────────────────┘
```

### 架构原则

1. **单一职责**: 每个组件只负责一个明确的功能
2. **依赖倒置**: 高层模块不依赖低层模块，都依赖抽象
3. **开闭原则**: 对扩展开放，对修改关闭
4. **接口隔离**: 客户端不应依赖不需要的接口
5. **依赖注入**: 通过依赖注入管理组件间依赖关系

### 关键架构决策

1. **MVVM 模式**: 采用 Model-View-ViewModel 模式，分离 UI 逻辑和业务逻辑
2. **响应式设计**: 使用 Combine 框架实现响应式数据流
3. **模块化设计**: 将功能拆分为独立模块，便于测试和维护
4. **事件驱动**: 使用事件总线处理跨组件通信

## 组件和接口

### 核心组件

#### 1. LauncherApp (主应用)
- **职责**: 应用入口点，管理应用生命周期
- **接口**: `@main` 应用入口，AppDelegate 协议实现
- **依赖**: 所有其他核心组件
- **并发安全**: `@MainActor` 标记，确保在主线程运行

#### 2. ApplicationScanner (应用扫描器) - Actor
- **职责**: 扫描系统中的应用，维护应用列表
- **接口**:
  ```swift
  actor ApplicationScanner: ApplicationScannerProtocol {
      private let fileMonitor: FileSystemMonitor
      private let launchServices: LaunchServicesAPI
      
      nonisolated var onApplicationsChanged: ((Set<ApplicationChange>) -> Void)?
      
      func scanApplications() async -> [ApplicationInfo]
      func startMonitoring() async
      func stopMonitoring() async
  }
  
  protocol ApplicationScannerProtocol {
      func scanApplications() async -> [ApplicationInfo]
      func startMonitoring() async
      func stopMonitoring() async
      var onApplicationsChanged: ((Set<ApplicationChange>) -> Void)? { get set }
  }
  ```
- **实现**: 使用 Launch Services API 和 File System Events
- **并发安全**: Actor 确保线程安全

#### 3. ApplicationGridViewModel (应用网格视图模型) - @MainActor
- **职责**: 管理应用网格的显示逻辑和状态
- **接口**:
  ```swift
  @MainActor
  class ApplicationGridViewModel: ObservableObject, Sendable {
      @Published var applications: [ApplicationInfo]
      @Published var currentPage: Int
      @Published var isEditing: Bool
      @Published var searchQuery: String
      
      private let folderManager: FolderManagerProtocol
      private let layoutManager: LayoutManagerProtocol
      
      func moveApplication(_ appId: String, to position: GridPosition) async
      func deleteApplication(_ appId: String) async
      func createFolder(with apps: [String]) async
      func toggleEditMode()
  }
  ```
- **并发安全**: `@MainActor` 确保 UI 更新在主线程

#### 4. SearchViewModel (搜索视图模型) - @MainActor
- **职责**: 管理搜索功能和搜索结果
- **接口**:
  ```swift
  @MainActor
  class SearchViewModel: ObservableObject, Sendable {
      @Published var searchResults: [ApplicationInfo]
      @Published var isSearching: Bool
      
      private let searchEngine: SearchEngineProtocol
      private let historyManager: SearchHistoryManagerProtocol
      
      func search(query: String) async
      func clearSearch()
      func launchApplication(_ appId: String) async
      func getSearchHistory() -> [SearchHistoryItem]
      func clearSearchHistory()
  }
  ```

#### 5. FolderManager (文件夹管理器) - Actor
- **职责**: 管理文件夹的创建、编辑和删除
- **接口**:
  ```swift
  actor FolderManager: FolderManagerProtocol {
      private let persistence: FolderPersistenceProtocol
      
      func createFolder(name: String, applications: [String]) async -> FolderInfo
      func addToFolder(appId: String, folderId: String) async
      func removeFromFolder(appId: String, folderId: String) async
      func renameFolder(folderId: String, newName: String) async
      func deleteFolder(folderId: String) async
      func generateFolderIcon(for folderId: String) async -> NSImage?
  }
  
  protocol FolderManagerProtocol {
      func createFolder(name: String, applications: [String]) async -> FolderInfo
      func addToFolder(appId: String, folderId: String) async
      func removeFromFolder(appId: String, folderId: String) async
      func renameFolder(folderId: String, newName: String) async
      func deleteFolder(folderId: String) async
  }
  ```

#### 6. PageNavigator (页面导航器) - @MainActor
- **职责**: 管理多页面导航和页面切换
- **接口**:
  ```swift
  @MainActor
  class PageNavigator: ObservableObject, Sendable {
      @Published var currentPage: Int
      @Published var totalPages: Int
      @Published var pageIndicators: [PageIndicator]
      
      func goToPage(_ page: Int)
      func goToNextPage()
      func goToPreviousPage()
      func updatePageIndicators()
      func calculatePageForPosition(_ position: GridPosition) -> Int
  }
  ```

#### 7. SettingsManager (设置管理器) - Actor
- **职责**: 管理用户设置和偏好
- **接口**:
  ```swift
  actor SettingsManager: SettingsManagerProtocol {
      private let userDefaults: UserDefaults
      private let keychain: KeychainManagerProtocol
      
      var iconSize: IconSize { get async set }
      var gridColumns: Int { get async set }
      var gridRows: Int { get async set }
      var shortcutKey: ShortcutKey { get async set }
      var enableGestures: Bool { get async set }
      var appearanceMode: AppearanceMode { get async set }
      var language: AppLanguage { get async set }
      
      func saveSettings() async throws
      func loadSettings() async throws -> AppSettings
      func resetToDefaults() async
      func exportSettings() async throws -> Data
      func importSettings(_ data: Data) async throws
  }
  
  protocol SettingsManagerProtocol {
      var iconSize: IconSize { get async set }
      var gridColumns: Int { get async set }
      var gridRows: Int { get async set }
      var shortcutKey: ShortcutKey { get async set }
      var enableGestures: Bool { get async set }
      var appearanceMode: AppearanceMode { get async set }
      var language: AppLanguage { get async set }
      
      func saveSettings() async throws
      func loadSettings() async throws -> AppSettings
      func resetToDefaults() async
  }
  ```

#### 8. LauncherStateManager (Launcher 状态管理器) - Actor
- **职责**: 管理窗口显示/隐藏状态和动画
- **接口**:
  ```swift
  actor LauncherStateManager {
      private let animationManager: AnimationManagerProtocol
      private let windowController: WindowControllerProtocol
      
      var isVisible: Bool { get async }
      var animationInProgress: Bool { get async }
      
      func showLauncher() async
      func hideLauncher() async
      func toggleLauncher() async
      func getWindowFrame() async -> CGRect
      func setWindowFrame(_ frame: CGRect) async
      func updateBackgroundBlur(_ intensity: Double) async
  }
  ```

#### 9. KeyboardShortcutManager (键盘快捷键管理器) - Actor
- **职责**: 管理全局快捷键注册和响应
- **接口**:
  ```swift
  actor KeyboardShortcutManager {
      private let eventMonitor: EventMonitorProtocol
      private let settingsManager: SettingsManagerProtocol
      
      func registerGlobalShortcut(_ shortcut: KeyboardShortcut) async throws
      func unregisterGlobalShortcut(_ shortcut: KeyboardShortcut) async
      func enableShortcuts() async
      func disableShortcuts() async
      func handleKeyEvent(_ event: NSEvent) async -> Bool
      
      struct KeyboardShortcut: Hashable, Sendable {
          let keyCode: UInt16
          let modifiers: NSEvent.ModifierFlags
          let identifier: String
      }
  }
  ```

#### 10. GestureManager (手势管理器) - Actor
- **职责**: 管理触控板手势识别和处理
- **接口**:
  ```swift
  actor GestureManager {
      private let gestureRecognizer: GestureRecognizerProtocol
      private let settingsManager: SettingsManagerProtocol
      
      var isEnabled: Bool { get async set }
      var misrecognitionRate: Double { get async }
      
      func enableGestures() async
      func disableGestures() async
      func recognizeGesture(_ event: NSEvent) async -> GestureType?
      func calibrateSensitivity() async
      func getGestureStatistics() async -> GestureStatistics
      
      enum GestureType: Sendable {
          case pinchOpen
          case pinchClose
          case swipeLeft
          case swipeRight
          case fourFingerPinch
          case fiveFingerPinch
      }
  }
  ```

#### 11. ContextMenuManager (上下文菜单管理器) - @MainActor
- **职责**: 管理上下文菜单的创建和显示
- **接口**:
  ```swift
  @MainActor
  class ContextMenuManager {
      func createContextMenu(for application: ApplicationInfo) -> NSMenu
      func createContextMenu(for folder: FolderInfo) -> NSMenu
      func showContextMenu(at location: CGPoint, for target: ContextMenuTarget)
      func updateContextMenuItems()
      
      enum ContextMenuTarget: Sendable {
          case application(ApplicationInfo)
          case folder(FolderInfo)
          case background
      }
  }
  ```

#### 12. SearchHistoryManager (搜索历史管理器) - Actor
- **职责**: 管理搜索历史记录
- **接口**:
  ```swift
  actor SearchHistoryManager {
      private let persistence: SearchHistoryPersistenceProtocol
      private let maxHistoryItems: Int = 100
      
      func addSearchQuery(_ query: String, timestamp: Date = Date()) async
      func getSearchHistory(limit: Int? = nil) async -> [SearchHistoryItem]
      func clearSearchHistory() async
      func removeSearchItem(_ id: UUID) async
      func exportSearchHistory() async throws -> Data
      
      struct SearchHistoryItem: Identifiable, Codable, Sendable {
          let id: UUID
          let query: String
          let timestamp: Date
          let resultCount: Int?
      }
  }
  ```

#### 13. AnimationManager (动画管理器) - @MainActor
- **职责**: 管理所有动画效果
- **接口**:
  ```swift
  @MainActor
  class AnimationManager: AnimationManagerProtocol {
      func launchAnimation(for app: ApplicationInfo) -> Animation
      func pageTransitionAnimation() -> Animation
      func editModeAnimation() -> Animation
      func folderCreationAnimation() -> Animation
      func iconDragAnimation() -> Animation
      func launcherShowAnimation() -> Animation
      func launcherHideAnimation() -> Animation
      func reduceMotionAnimation() -> Animation
  }
  
  protocol AnimationManagerProtocol {
      func launchAnimation(for app: ApplicationInfo) -> Animation
      func pageTransitionAnimation() -> Animation
      func editModeAnimation() -> Animation
      func folderCreationAnimation() -> Animation
      func iconDragAnimation() -> Animation
  }
  ```

#### 14. AccessibilityManager (可访问性管理器) - @MainActor
- **职责**: 管理可访问性功能
- **接口**:
  ```swift
  @MainActor
  class AccessibilityManager {
      func setupVoiceOverSupport()
      func setupKeyboardNavigation()
      func updateForHighContrastMode()
      func reduceMotionIfNeeded()
      func updateForDisplaySettings()
      func announce(_ message: String)
      func getAccessibilitySettings() -> AccessibilitySettings
  }
  ```

#### 15. DIContainer (依赖注入容器)
- **职责**: 管理组件依赖关系和生命周期
- **接口**:
  ```swift
  class DIContainer {
      static let shared = DIContainer()
      
      // 注册方法
      func register<T>(_ type: T.Type, factory: @escaping () -> T)
      func register<T>(_ type: T.Type, instance: T)
      func register<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T)
      
      // 解析方法
      func resolve<T>(_ type: T.Type) -> T
      func resolve<T>(_ type: T.Type, name: String) -> T
      
      // 生命周期管理
      func reset()
      func remove<T>(_ type: T.Type)
      
      // 作用域支持
      enum Scope {
          case singleton
          case transient
          case scoped(String)
      }
  }
  ```

### 组件间通信

#### 事件总线协议 + 依赖注入
```swift
protocol EventBusProtocol: Sendable {
    // 应用相关事件
    var applicationAdded: AnyPublisher<ApplicationInfo, Never> { get }
    var applicationRemoved: AnyPublisher<String, Never> { get }
    var applicationLaunched: AnyPublisher<String, Never> { get }
    
    // UI 相关事件
    var editModeChanged: AnyPublisher<Bool, Never> { get }
    var searchQueryChanged: AnyPublisher<String, Never> { get }
    var pageChanged: AnyPublisher<Int, Never> { get }
    
    // 系统事件
    var systemAppearanceChanged: AnyPublisher<AppearanceMode, Never> { get }
    var accessibilitySettingsChanged: AnyPublisher<Void, Never> { get }
    
    // 发布方法
    func publishApplicationAdded(_ app: ApplicationInfo)
    func publishApplicationRemoved(_ appId: String)
    func publishApplicationLaunched(_ appId: String)
    func publishEditModeChanged(_ isEditing: Bool)
    func publishSearchQueryChanged(_ query: String)
    func publishPageChanged(_ page: Int)
    func publishSystemAppearanceChanged(_ mode: AppearanceMode)
    func publishAccessibilitySettingsChanged()
}

class EventBus: EventBusProtocol, Sendable {
    private let applicationAddedSubject = PassthroughSubject<ApplicationInfo, Never>()
    private let applicationRemovedSubject = PassthroughSubject<String, Never>()
    private let applicationLaunchedSubject = PassthroughSubject<String, Never>()
    private let editModeChangedSubject = PassthroughSubject<Bool, Never>()
    private let searchQueryChangedSubject = PassthroughSubject<String, Never>()
    private let pageChangedSubject = PassthroughSubject<Int, Never>()
    private let systemAppearanceChangedSubject = PassthroughSubject<AppearanceMode, Never>()
    private let accessibilitySettingsChangedSubject = PassthroughSubject<Void, Never>()
    
    // 发布者属性
    var applicationAdded: AnyPublisher<ApplicationInfo, Never> {
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
    
    var systemAppearanceChanged: AnyPublisher<AppearanceMode, Never> {
        systemAppearanceChangedSubject.eraseToAnyPublisher()
    }
    
    var accessibilitySettingsChanged: AnyPublisher<Void, Never> {
        accessibilitySettingsChangedSubject.eraseToAnyPublisher()
    }
    
    // 发布方法
    func publishApplicationAdded(_ app: ApplicationInfo) {
        applicationAddedSubject.send(app)
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
    
    func publishSystemAppearanceChanged(_ mode: AppearanceMode) {
        systemAppearanceChangedSubject.send(mode)
    }
    
    func publishAccessibilitySettingsChanged() {
        accessibilitySettingsChangedSubject.send(())
    }
}
```

#### 依赖注入配置
```swift
extension DIContainer {
    func configureDefaultDependencies() {
        // 注册事件总线
        register(EventBusProtocol.self, scope: .singleton) { _ in
            EventBus()
        }
        
        // 注册服务层 Actors
        register(ApplicationScannerProtocol.self, scope: .singleton) { container in
            ApplicationScanner()
        }
        
        register(FolderManagerProtocol.self, scope: .singleton) { container in
            FolderManager()
        }
        
        register(SettingsManagerProtocol.self, scope: .singleton) { container in
            SettingsManager()
        }
        
        // 注册管理器
        register(LauncherStateManager.self, scope: .singleton) { container in
            LauncherStateManager()
        }
        
        register(KeyboardShortcutManager.self, scope: .singleton) { container in
            KeyboardShortcutManager()
        }
        
        register(GestureManager.self, scope: .singleton) { container in
            GestureManager()
        }
        
        // 注册 ViewModels (@MainActor)
        register(ApplicationGridViewModel.self, scope: .transient) { container in
            ApplicationGridViewModel()
        }
        
        register(SearchViewModel.self, scope: .transient) { container in
            SearchViewModel()
        }
        
        // 注册其他组件
        register(SearchHistoryManager.self, scope: .singleton) { container in
            SearchHistoryManager()
        }
        
        register(ContextMenuManager.self, scope: .singleton) { container in
            ContextMenuManager()
        }
        
        register(AccessibilityManager.self, scope: .singleton) { container in
            AccessibilityManager()
        }
        
        register(AnimationManagerProtocol.self, scope: .singleton) { container in
            AnimationManager()
        }
    }
}
```

#### 数据流
```
用户操作 → View → ViewModel → 业务逻辑 → 数据层 → 系统 API
      ↑                                      ↓
      └────── 事件总线(依赖注入) ←──────────┘
```

## 数据模型

### 核心数据模型 (全部实现 Sendable)

#### 1. ApplicationInfo (应用信息)
```swift
struct ApplicationInfo: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String // UUID 或 bundle identifier
    let name: String
    let bundleIdentifier: String
    let bundleURL: URL
    let iconURL: URL?
    let isSystemApp: Bool
    let installDate: Date
    let lastLaunchDate: Date?
    let launchCount: Int
    let localizedName: LocalizedString // 国际化支持
    
    // 计算属性
    var displayName: String { localizedName.currentLanguage }
    var isRunning: Bool { false } // 需要系统 API 检查
    var canBeDeleted: Bool { !isSystemApp }
    
    // 本地化支持
    struct LocalizedString: Codable, Equatable, Hashable, Sendable {
        let english: String
        let chineseSimplified: String?
        let chineseTraditional: String?
        let japanese: String?
        let korean: String?
        
        var currentLanguage: String {
            // 根据系统语言返回对应字符串
            let locale = Locale.current
            if locale.identifier.contains("zh-Hans"), let chinese = chineseSimplified {
                return chinese
            } else if locale.identifier.contains("zh-Hant"), let chinese = chineseTraditional {
                return chinese
            } else if locale.identifier.contains("ja"), let japanese = japanese {
                return japanese
            } else if locale.identifier.contains("ko"), let korean = korean {
                return korean
            }
            return english
        }
    }
}
```

#### 2. GridPosition (网格位置)
```swift
struct GridPosition: Codable, Equatable, Hashable, Sendable {
    let page: Int
    let row: Int
    let column: Int
    
    static let zero = GridPosition(page: 0, row: 0, column: 0)
    
    func next(in gridSize: GridSize) -> GridPosition {
        var newColumn = column + 1
        var newRow = row
        var newPage = page
        
        if newColumn >= gridSize.columns {
            newColumn = 0
            newRow += 1
            
            if newRow >= gridSize.rows {
                newRow = 0
                newPage += 1
            }
        }
        
        return GridPosition(page: newPage, row: newRow, column: newColumn)
    }
}

struct GridSize: Codable, Equatable, Hashable, Sendable {
    let columns: Int
    let rows: Int
    
    static let `default` = GridSize(columns: 7, rows: 5)
}
```

#### 3. FolderInfo (文件夹信息)
```swift
struct FolderInfo: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var name: LocalizedString // 支持多语言
    var applications: [String] // 应用 ID 列表
    var creationDate: Date
    var modifiedDate: Date
    var iconPreview: Data? // 文件夹图标预览
    var colorTheme: FolderColorTheme // 文件夹颜色主题
    
    var applicationCount: Int { applications.count }
    var isEmpty: Bool { applications.isEmpty }
    
    enum FolderColorTheme: String, Codable, Sendable {
        case blue, green, orange, purple, pink, gray
    }
}
```

#### 4. UserLayout (用户布局)
```swift
struct UserLayout: Codable, Equatable, Sendable {
    var applicationPositions: [String: GridPosition] // 应用ID -> 位置
    var folders: [FolderInfo]
    var pageOrder: [Int] // 页面顺序
    var lastModified: Date
    var version: Int = 1
    
    // 验证方法
    func isValid() -> Bool {
        // 检查是否有重复位置
        var positionSet = Set<GridPosition>()
        for position in applicationPositions.values {
            if positionSet.contains(position) {
                return false
            }
            positionSet.insert(position)
        }
        
        // 检查所有应用是否都有有效位置
        for appId in applicationPositions.keys {
            if applicationPositions[appId] == nil {
                return false
            }
        }
        
        return true
    }
    
    // 加密支持
    func encrypted() throws -> Data {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return try KeychainManager.shared.encrypt(data)
    }
    
    static func decrypted(from data: Data) throws -> UserLayout {
        let decryptedData = try KeychainManager.shared.decrypt(data)
        let decoder = JSONDecoder()
        return try decoder.decode(UserLayout.self, from: decryptedData)
    }
}
```

#### 5. AppSettings (应用设置)
```swift
struct AppSettings: Codable, Equatable, Sendable {
    var iconSize: IconSize = .medium
    var gridColumns: Int = 7
    var gridRows: Int = 5
    var horizontalSpacing: Double = 0  // 横向间距，0 表示使用动态计算值
    var verticalSpacing: Double = 0    // 纵向间距，0 表示使用动态计算值
    var shortcutKey: ShortcutKey = .f4
    var enableGestures: Bool = true
    var appearanceMode: AppearanceMode = .auto
    var enableAnimations: Bool = true
    var reduceMotion: Bool = false
    var highContrast: Bool = false
    var language: AppLanguage = .system
    var backgroundBlurIntensity: Double = 0.7
    var searchHistoryEnabled: Bool = true
    var dockIntegrationEnabled: Bool = true
    var missionControlIntegrationEnabled: Bool = true
    
    /// 根据屏幕长宽比和网格长宽比动态计算横向间距
    /// - Parameters:
    ///   - screenAspectRatio: 屏幕宽高比（宽/高）
    ///   - gridAspectRatio: 网格宽高比（列数/行数）
    /// - Returns: 计算后的横向间距
    func calculateHorizontalSpacing(screenAspectRatio: Double, gridAspectRatio: Double) -> Double {
        // 如果用户设置了自定义值，使用用户值
        if horizontalSpacing > 0 { return horizontalSpacing }
        // 否则根据比例差动态计算
        let ratio = screenAspectRatio / gridAspectRatio
        let baseSpacing: Double = 20.0
        return baseSpacing * ratio
    }
    
    /// 根据屏幕长宽比和网格长宽比动态计算纵向间距
    /// - Parameters:
    ///   - screenAspectRatio: 屏幕宽高比（宽/高）
    ///   - gridAspectRatio: 网格宽高比（列数/行数）
    /// - Returns: 计算后的纵向间距
    func calculateVerticalSpacing(screenAspectRatio: Double, gridAspectRatio: Double) -> Double {
        // 如果用户设置了自定义值，使用用户值
        if verticalSpacing > 0 { return verticalSpacing }
        // 否则根据比例差动态计算
        let ratio = gridAspectRatio / screenAspectRatio
        let baseSpacing: Double = 20.0
        return baseSpacing * ratio
    }
    
    enum IconSize: String, Codable, Sendable {
        case small, medium, large
    }
    
    enum ShortcutKey: String, Codable, Sendable {
        case f4, fnF4, custom
    }
    
    enum AppearanceMode: String, Codable, Sendable {
        case light, dark, auto
    }
    
    enum AppLanguage: String, Codable, Sendable {
        case system, english, chineseSimplified, chineseTraditional, japanese, korean
    }
}
```

#### 6. SearchResult (搜索结果)
```swift
struct SearchResult: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let application: ApplicationInfo
    let matchScore: Double // 0.0-1.0
    let matchedFields: [String] // 匹配的字段
    let timestamp: Date
    
    static func sortByRelevance(_ results: [SearchResult]) -> [SearchResult] {
        results.sorted { $0.matchScore > $1.matchScore }
    }
}
```

#### 7. DockIntegrationData (Dock 集成数据)
```swift
struct DockIntegrationData: Codable, Equatable, Sendable {
    var dockItems: [DockItem]
    var lastSyncDate: Date
    var syncEnabled: Bool = true
    
    struct DockItem: Codable, Equatable, Hashable, Sendable {
        let appId: String
        let position: Int
        let isPinned: Bool
        let addedFromLauncher: Bool
    }
}
```

#### 8. MissionControlIntegrationData (Mission Control 集成数据)
```swift
struct MissionControlIntegrationData: Codable, Equatable, Sendable {
    var desktopSpaces: [DesktopSpace]
    var currentSpaceId: String?
    var showInMissionControl: Bool = true
    
    struct DesktopSpace: Codable, Equatable, Hashable, Sendable {
        let id: String
        let name: String
        let applications: [String] // 应用ID列表
        let position: Int
    }
}
```

#### 9. UniversalBinaryInfo (通用二进制信息)
```swift
struct UniversalBinaryInfo: Codable, Equatable, Sendable {
    let supportsIntel: Bool
    let supportsAppleSilicon: Bool
    let architecture: Architecture
    let optimizationLevel: OptimizationLevel
    
    enum Architecture: String, Codable, Sendable {
        case universal, intel, appleSilicon
    }
    
    enum OptimizationLevel: String, Codable, Sendable {
        case none, basic, optimized, highlyOptimized
    }
    
    var currentArchitecture: Architecture {
        #if arch(x86_64)
        return .intel
        #elseif arch(arm64)
        return .appleSilicon
        #else
        return .universal
        #endif
    }
}
```

### 数据持久化

#### 存储策略
1. **用户布局**: Core Data + Keychain 加密存储，支持版本迁移
2. **应用设置**: UserDefaults + Keychain（敏感设置），支持iCloud同步
3. **缓存数据**: 文件系统缓存，定期清理，支持清除缓存
4. **临时数据**: 内存缓存，应用生命周期内有效
5. **搜索历史**: SQLite 数据库，支持加密和清理
6. **国际化资源**: 本地化文件（.strings, .stringsdict），支持动态加载

#### Keychain 存储方案
```swift
actor KeychainManager: KeychainManagerProtocol {
    static let shared = KeychainManager()
    
    private let serviceName = "com.sunz.launcher"
    private let accessGroup: String? = nil // 如果需要共享Keychain访问
    
    // 加密密钥管理
    private var encryptionKey: Data?
    
    func saveEncryptedData(_ data: Data, for key: String) async throws {
        let encryptedData = try encrypt(data)
        try saveToKeychain(encryptedData, for: key)
    }
    
    func loadEncryptedData(for key: String) async throws -> Data {
        let encryptedData = try loadFromKeychain(for: key)
        return try decrypt(encryptedData)
    }
    
    func deleteEncryptedData(for key: String) async throws {
        try deleteFromKeychain(for: key)
    }
    
    func rotateEncryptionKeys() async throws {
        // 生成新密钥
        let newKey = try generateEncryptionKey()
        
        // 重新加密所有数据
        try await reencryptAllData(with: newKey)
        
        // 更新密钥
        encryptionKey = newKey
    }
    
    private func encrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw KeychainError.encryptionKeyNotFound
        }
        // 使用 AES-GCM 加密
        return try AES.GCM.seal(data, using: SymmetricKey(data: key)).combined
    }
    
    private func decrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw KeychainError.encryptionKeyNotFound
        }
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: SymmetricKey(data: key))
    }
    
    private func generateEncryptionKey() throws -> Data {
        var key = Data(count: 32) // 256位密钥
        let result = key.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw KeychainError.keyGenerationFailed
        }
        return key
    }
    
    enum KeychainError: Error, Sendable {
        case encryptionKeyNotFound
        case keyGenerationFailed
        case encryptionFailed
        case decryptionFailed
        case keychainAccessFailed(OSStatus)
    }
}

protocol KeychainManagerProtocol {
    func saveEncryptedData(_ data: Data, for key: String) async throws
    func loadEncryptedData(for key: String) async throws -> Data
    func deleteEncryptedData(for key: String) async throws
    func rotateEncryptionKeys() async throws
}
```

#### 国际化设计
```swift
class LocalizationManager {
    static let shared = LocalizationManager()
    
    private var currentLanguage: AppLanguage = .system
    private var localizationBundles: [AppLanguage: Bundle] = [:]
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        updateBundleForLanguage(language)
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    func localizedString(for key: String, table: String? = nil) -> String {
        let bundle = localizationBundles[currentLanguage] ?? Bundle.main
        return NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
    
    func localizedString(for key: String, arguments: [CVarArg]) -> String {
        let format = localizedString(for: key)
        return String(format: format, arguments: arguments)
    }
    
    func pluralizedString(for key: String, count: Int) -> String {
        let format = localizedString(for: key)
        let rule = pluralizationRule(for: currentLanguage, count: count)
        return String.localizedStringWithFormat(format, count)
    }
    
    private func updateBundleForLanguage(_ language: AppLanguage) {
        guard let path = Bundle.main.path(forResource: language.resourceName, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            localizationBundles[language] = Bundle.main
            return
        }
        localizationBundles[language] = bundle
    }
    
    private func pluralizationRule(for language: AppLanguage, count: Int) -> NSLocale.PluralizationRule {
        // 根据语言返回正确的复数规则
        switch language {
        case .english:
            return count == 1 ? .one : .other
        case .chineseSimplified, .chineseTraditional:
            return .other // 中文没有复数形式
        case .japanese:
            return .other // 日语通常没有复数形式
        case .korean:
            return .other // 韩语通常没有复数形式
        case .system:
            return pluralizationRule(for: systemLanguage, count: count)
        }
    }
    
    private var systemLanguage: AppLanguage {
        let locale = Locale.current
        if locale.identifier.contains("zh-Hans") {
            return .chineseSimplified
        } else if locale.identifier.contains("zh-Hant") {
            return .chineseTraditional
        } else if locale.identifier.contains("ja") {
            return .japanese
        } else if locale.identifier.contains("ko") {
            return .korean
        }
        return .english
    }
}

// 本地化文件结构
/*
 Localizable.strings (英文)
   "app.name" = "macOS Launcher";
   "search.placeholder" = "Search applications...";
   "folder.default.name" = "Other";
   "empty.state.message" = "No applications found";
 
 Localizable.strings (简体中文)
   "app.name" = "macOS 启动器";
   "search.placeholder" = "搜索应用程序...";
   "folder.default.name" = "其他";
   "empty.state.message" = "未找到应用程序";
 
 Localizable.stringsdict (复数支持)
   <dict>
     <key>applications.count</key>
     <dict>
       <key>NSStringLocalizedFormatKey</key>
       <string>%#@applications@</string>
       <key>applications</key>
       <dict>
         <key>NSStringFormatSpecTypeKey</key>
         <string>NSStringPluralRuleType</string>
         <key>NSStringFormatValueTypeKey</key>
         <string>d</string>
         <key>one</key>
         <string>%d application</string>
         <key>other</key>
         <string>%d applications</string>
       </dict>
     </dict>
   </dict>
 */
```

#### 数据迁移
```swift
actor DataMigrator: DataMigratorProtocol {
    private let currentVersion = 2
    private let backupManager: BackupManagerProtocol
    private let keychainManager: KeychainManagerProtocol
    
    func migrateIfNeeded() async throws {
        let oldVersion = try getStoredVersion()
        
        if oldVersion < currentVersion {
            try await backupBeforeMigration()
            try await migrate(from: oldVersion, to: currentVersion)
            try updateStoredVersion(currentVersion)
        }
    }
    
    func migrate(from oldVersion: Int, to newVersion: Int) async throws {
        for version in oldVersion..<newVersion {
            switch version {
            case 1:
                try await migrateFromV1ToV2()
            case 2:
                try await migrateFromV2ToV3()
            default:
                throw MigrationError.unsupportedVersion(version)
            }
        }
    }
    
    private func migrateFromV1ToV2() async throws {
        // V1 -> V2 迁移：添加加密支持和国际化
        // 1. 加密现有用户布局
        // 2. 迁移设置到新的国际化格式
        // 3. 更新数据模型版本
    }
    
    private func migrateFromV2ToV3() async throws {
        // V2 -> V3 迁移：添加通用二进制支持
        // 1. 检测架构并优化数据存储
        // 2. 更新性能相关设置
    }
    
    func backupBeforeMigration() async throws {
        try await backupManager.createBackup()
    }
    
    func rollbackIfFailed() async throws {
        try await backupManager.restoreFromBackup()
    }
    
    enum MigrationError: Error, Sendable {
        case unsupportedVersion(Int)
        case migrationFailed(Int, Int, Error)
        case backupFailed
        case rollbackFailed
    }
}

protocol DataMigratorProtocol {
    func migrateIfNeeded() async throws
    func migrate(from oldVersion: Int, to newVersion: Int) async throws
    func backupBeforeMigration() async throws
    func rollbackIfFailed() async throws
}
```

#### 数据验证
```swift
actor DataValidator: DataValidatorProtocol {
    func validate(application: ApplicationInfo) throws {
        // 验证应用信息
        guard !application.id.isEmpty else {
            throw ValidationError.invalidApplicationId
        }
        
        guard !application.name.isEmpty else {
            throw ValidationError.invalidApplicationName
        }
        
        guard !application.bundleIdentifier.isEmpty else {
            throw ValidationError.invalidBundleIdentifier
        }
        
        // 验证URL可访问性
        guard FileManager.default.fileExists(atPath: application.bundleURL.path) else {
            throw ValidationError.applicationNotFound(application.bundleURL)
        }
    }
    
    func validate(layout: UserLayout) throws {
        // 验证布局数据
        guard layout.isValid() else {
            throw ValidationError.invalidLayout
        }
        
        // 验证版本兼容性
        guard layout.version <= Constants.currentLayoutVersion else {
            throw ValidationError.unsupportedLayoutVersion(layout.version)
        }
        
        // 验证修改时间合理性
        guard layout.lastModified <= Date() else {
            throw ValidationError.futureModificationDate(layout.lastModified)
        }
    }
    
    func validate(folder: FolderInfo) throws {
        // 验证文件夹信息
        guard !folder.id.isEmpty else {
            throw ValidationError.invalidFolderId
        }
        
        guard !folder.name.currentLanguage.isEmpty else {
            throw ValidationError.invalidFolderName
        }
        
        // 验证应用ID存在性（在实际实现中需要检查）
        // 验证颜色主题有效性
        guard FolderInfo.FolderColorTheme(rawValue: folder.colorTheme.rawValue) != nil else {
            throw ValidationError.invalidColorTheme(folder.colorTheme.rawValue)
        }
    }
    
    func validate(settings: AppSettings) throws {
        // 验证设置值范围
        guard settings.gridColumns >= 3 && settings.gridColumns <= 12 else {
            throw ValidationError.invalidGridSize(settings.gridColumns, settings.gridRows)
        }
        
        guard settings.gridRows >= 3 && settings.gridRows <= 10 else {
            throw ValidationError.invalidGridSize(settings.gridColumns, settings.gridRows)
        }
        
        guard settings.backgroundBlurIntensity >= 0 && settings.backgroundBlurIntensity <= 1 else {
            throw ValidationError.invalidBlurIntensity(settings.backgroundBlurIntensity)
        }
    }
    
    enum ValidationError: Error, Sendable {
        case invalidApplicationId
        case invalidApplicationName
        case invalidBundleIdentifier
        case applicationNotFound(URL)
        case invalidLayout
        case unsupportedLayoutVersion(Int)
        case futureModificationDate(Date)
        case invalidFolderId
        case invalidFolderName
        case invalidColorTheme(String)
        case invalidGridSize(Int, Int)
        case invalidBlurIntensity(Double)
    }
}

protocol DataValidatorProtocol {
    func validate(application: ApplicationInfo) throws
    func validate(layout: UserLayout) throws
    func validate(folder: FolderInfo) throws
    func validate(settings: AppSettings) throws
}
```

### 数据流设计

#### 应用数据流
```
系统API → ApplicationScanner → 事件总线 → ApplicationGridViewModel → UI
      ↓                              ↑
  文件监控 ←───────────────────────┘
```

#### 用户操作数据流
```
用户输入 → View → ViewModel → 业务逻辑 → 数据存储 → 持久化
      ↓                                    ↑
      └────────── 反馈更新 ←──────────────┘
```

#### 搜索数据流
```
搜索输入 → SearchViewModel → 搜索算法 → 过滤排序 → 搜索结果 → UI
      ↓                                          ↑
      └────────── 实时更新 ←────────────────────┘
```

### 性能优化

#### 内存管理目标
- **空闲状态**: ≤ 50MB
- **正常使用**: ≤ 150MB
- **峰值使用**: ≤ 200MB（短暂峰值）
- **内存警告阈值**: 180MB（触发清理）

#### 数据缓存
```swift
actor ApplicationIconCache: ApplicationIconCacheProtocol {
    private let memoryCache = NSCache<NSString, NSImage>()
    private let diskCacheURL: URL
    private let memoryWarningObserver: NSObjectProtocol?
    
    // 内存限制配置
    private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50MB
    private let maxDiskCacheSize: Int = 200 * 1024 * 1024 // 200MB
    private let preferredIconSize: CGSize
    
    init() {
        memoryCache.totalCostLimit = maxMemoryCacheSize
        // 根据架构优化缓存策略
        #if arch(arm64)
        // Apple Silicon: 更大的缓存，更积极的预加载
        preferredIconSize = CGSize(width: 256, height: 256)
        #else
        // Intel: 适中的缓存，按需加载
        preferredIconSize = CGSize(width: 128, height: 128)
        #endif
        
        // 监听内存警告
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryWarning()
            }
        }
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func getIcon(for appId: String) async -> NSImage? {
        // 1. 检查内存缓存
        if let cachedImage = memoryCache.object(forKey: appId as NSString) {
            return cachedImage
        }
        
        // 2. 检查磁盘缓存
        if let diskImage = await loadFromDiskCache(appId: appId) {
            // 存入内存缓存
            memoryCache.setObject(diskImage, forKey: appId as NSString)
            return diskImage
        }
        
        // 3. 从文件系统加载
        if let originalImage = await loadOriginalIcon(appId: appId) {
            // 调整大小并缓存
            let resizedImage = await resizeImage(originalImage, to: preferredIconSize)
            
            // 缓存到内存和磁盘
            memoryCache.setObject(resizedImage, forKey: appId as NSString)
            await saveToDiskCache(resizedImage, appId: appId)
            
            return resizedImage
        }
        
        return nil
    }
    
    func setIcon(_ image: NSImage, for appId: String) async {
        let resizedImage = await resizeImage(image, to: preferredIconSize)
        memoryCache.setObject(resizedImage, forKey: appId as NSString)
        await saveToDiskCache(resizedImage, appId: appId)
    }
    
    func clearCache() async {
        memoryCache.removeAllObjects()
        await clearDiskCache()
    }
    
    func preloadIcons(for apps: [ApplicationInfo]) async {
        // 根据架构采用不同的预加载策略
        #if arch(arm64)
        // Apple Silicon: 并行预加载更多图标
        await withTaskGroup(of: Void.self) { group in
            for app in apps.prefix(20) { // 预加载前20个
                group.addTask {
                    _ = await self.getIcon(for: app.id)
                }
            }
        }
        #else
        // Intel: 串行预加载较少图标
        for app in apps.prefix(10) { // 预加载前10个
            _ = await getIcon(for: app.id)
        }
        #endif
    }
    
    private func handleMemoryWarning() async {
        // 减少内存缓存大小
        memoryCache.totalCostLimit = maxMemoryCacheSize / 2
        
        // 清理最久未使用的缓存项
        // 实际实现需要跟踪访问时间
        
        // 异步清理磁盘缓存
        await cleanupDiskCache()
    }
    
    private func resizeImage(_ image: NSImage, to size: CGSize) async -> NSImage {
        return await Task.detached {
            let newImage = NSImage(size: size)
            newImage.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: size))
            newImage.unlockFocus()
            return newImage
        }.value
    }
}

protocol ApplicationIconCacheProtocol {
    func getIcon(for appId: String) async -> NSImage?
    func setIcon(_ image: NSImage, for appId: String) async
    func clearCache() async
    func preloadIcons(for apps: [ApplicationInfo]) async
}
```

#### 懒加载
```swift
actor LazyApplicationLoader {
    private let applicationScanner: ApplicationScannerProtocol
    private let iconCache: ApplicationIconCacheProtocol
    private var loadingTasks: [String: Task<[ApplicationInfo], Error>] = [:]
    
    // 根据架构优化加载策略
    #if arch(arm64)
    private let preloadPageCount = 2 // Apple Silicon: 预加载2页
    private let maxConcurrentLoads = 4 // 并行加载数量
    #else
    private let preloadPageCount = 1 // Intel: 预加载1页
    private let maxConcurrentLoads = 2 // 并行加载数量
    #endif
    
    func loadVisibleApplications(page: Int, gridSize: GridSize) async throws -> [ApplicationInfo] {
        let taskId = "page-\(page)"
        
        // 如果已经在加载，返回现有任务
        if let existingTask = loadingTasks[taskId] {
            return try await existingTask.value
        }
        
        // 创建新的加载任务
        let task = Task<[ApplicationInfo], Error> {
            let allApps = try await applicationScanner.scanApplications()
            let appsPerPage = gridSize.columns * gridSize.rows
            let startIndex = page * appsPerPage
            let endIndex = min(startIndex + appsPerPage, allApps.count)
            
            guard startIndex < allApps.count else {
                return []
            }
            
            let pageApps = Array(allApps[startIndex..<endIndex])
            
            // 预加载图标
            await iconCache.preloadIcons(for: pageApps)
            
            return pageApps
        }
        
        loadingTasks[taskId] = task
        
        do {
            let result = try await task.value
            loadingTasks.removeValue(forKey: taskId)
            return result
        } catch {
            loadingTasks.removeValue(forKey: taskId)
            throw error
        }
    }
    
    func preloadNextPage() async {
        // 根据当前页面预加载下一页
        // 实现略
    }
    
    func cancelPreloading() {
        // 取消所有加载任务
        for task in loadingTasks.values {
            task.cancel()
        }
        loadingTasks.removeAll()
    }
}
```

#### 批量操作
```swift
actor BatchOperationManager {
    private let operationQueue = OperationQueue()
    private let maxBatchSize: Int
    
    init() {
        // 根据架构优化批量大小
        #if arch(arm64)
        maxBatchSize = 50 // Apple Silicon: 更大的批量
        operationQueue.maxConcurrentOperationCount = 8
        #else
        maxBatchSize = 25 // Intel: 适中的批量
        operationQueue.maxConcurrentOperationCount = 4
        #endif
    }
    
    func performBatchUpdates(_ updates: [DataUpdate]) async throws {
        // 分批处理更新
        let batches = updates.chunked(into: maxBatchSize)
        
        for batch in batches {
            try await withCheckedThrowingContinuation { continuation in
                let operation = BlockOperation {
                    do {
                        try self.processBatch(batch)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                
                operationQueue.addOperation(operation)
            }
        }
    }
    
    func optimizeBatchSize() -> Int {
        // 根据系统性能动态调整批量大小
        let processorCount = ProcessInfo.processInfo.processorCount
        let activeProcessorCount = ProcessInfo.processInfo.activeProcessorCount
        
        #if arch(arm64)
        // Apple Silicon: 根据性能核心和能效核心调整
        if processorCount >= 8 {
            return 100 // 高性能设备
        } else {
            return 50 // 标准设备
        }
        #else
        // Intel: 根据核心数调整
        if processorCount >= 4 {
            return 40
        } else {
            return 20
        }
        #endif
    }
    
    func scheduleBackgroundCleanup() async {
        // 在后台执行清理任务
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.cleanupTempFiles()
            }
            
            group.addTask {
                await self.optimizeDatabase()
            }
            
            group.addTask {
                await self.clearOldCache()
            }
        }
    }
    
    private func processBatch(_ batch: [DataUpdate]) throws {
        // 处理批量更新
        // 实现略
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

#### Universal Binary 优化
```swift
class ArchitectureOptimizer {
    static let shared = ArchitectureOptimizer()
    
    private let currentArchitecture: UniversalBinaryInfo.Architecture
    
    init() {
        #if arch(x86_64)
        currentArchitecture = .intel
        #elseif arch(arm64)
        currentArchitecture = .appleSilicon
        #else
        currentArchitecture = .universal
        #endif
    }
    
    func optimizedConfiguration() -> OptimizationConfiguration {
        switch currentArchitecture {
        case .intel:
            return OptimizationConfiguration(
                cacheStrategy: .moderate,
                concurrencyLevel: .medium,
                memoryLimit: 150 * 1024 * 1024, // 150MB
                preloadStrategy: .conservative,
                compressionLevel: .balanced
            )
        case .appleSilicon:
            return OptimizationConfiguration(
                cacheStrategy: .aggressive,
                concurrencyLevel: .high,
                memoryLimit: 200 * 1024 * 1024, // 200MB
                preloadStrategy: .aggressive,
                compressionLevel: .minimal
            )
        case .universal:
            return OptimizationConfiguration(
                cacheStrategy: .balanced,
                concurrencyLevel: .medium,
                memoryLimit: 175 * 1024 * 1024, // 175MB
                preloadStrategy: .balanced,
                compressionLevel: .balanced
            )
        }
    }
    
    struct OptimizationConfiguration {
        enum CacheStrategy {
            case conservative, moderate, aggressive, balanced
        }
        
        enum ConcurrencyLevel {
            case low, medium, high
        }
        
        enum PreloadStrategy {
            case conservative, balanced, aggressive
        }
        
        enum CompressionLevel {
            case minimal, balanced, aggressive
        }
        
        let cacheStrategy: CacheStrategy
        let concurrencyLevel: ConcurrencyLevel
        let memoryLimit: Int
        let preloadStrategy: PreloadStrategy
        let compressionLevel: CompressionLevel
    }
    
    func architectureSpecificCodePath() {
        #if arch(arm64)
        // Apple Silicon 优化代码路径
        useNeuralEngineIfAvailable()
        optimizeForPerformanceCores()
        #elseif arch(x86_64)
        // Intel 优化代码路径
        optimizeForAVX2()
        useIntelSpecificOptimizations()
        #endif
    }
    
    private func useNeuralEngineIfAvailable() {
        // 如果可用，使用神经引擎加速
        // 实现略
    }
    
    private func optimizeForPerformanceCores() {
        // 针对性能核心优化
        // 实现略
    }
    
    private func optimizeForAVX2() {
        // 使用 AVX2 指令集优化
        // 实现略
    }
    
    private func useIntelSpecificOptimizations() {
        // Intel 特定优化
        // 实现略
    }
}
```

### 错误处理

#### 数据错误类型
```swift
enum DataError: Error {
    case applicationNotFound(String)
    case invalidPosition(GridPosition)
    case folderCreationFailed(String)
    case dataCorruption
    case migrationFailed(Int, Int)
    case validationFailed(String)
    case persistenceError(Error)
}
```

#### 错误恢复策略
1. **重试机制**: 对临时错误自动重试
2. **回滚操作**: 对失败操作自动回滚
3. **数据修复**: 尝试修复损坏的数据
4. **用户通知**: 通知用户需要手动干预的错误

### 安全考虑

#### 数据加密
```swift
class DataEncryptor {
    func encryptLayout(_ layout: UserLayout) throws -> Data
    func decryptLayout(_ data: Data) throws -> UserLayout
    func rotateEncryptionKeys() throws
}
```

#### 访问控制
```swift
class AccessController {
    func canDeleteApplication(_ app: ApplicationInfo) -> Bool
    func canModifySystemApps() -> Bool
    func validateLaunchRequest(_ app: ApplicationInfo) -> Bool
}
```

（设计文档的"正确性属性"部分将在使用prework工具分析验收标准后继续编写）
## 正确性属性

*属性是一种特征或行为，应该在系统的所有有效执行中保持为真——本质上是对系统应该做什么的形式化陈述。属性作为人类可读规范和机器可验证正确性保证之间的桥梁。*

### 属性反思

在完成初步的prework分析后，我进行了属性反思以消除冗余：

1. **应用网格显示相关属性**：将多个网格显示属性合并为综合的网格渲染属性
2. **应用启动相关属性**：将启动流程的多个步骤合并为端到端的启动属性
3. **搜索功能相关属性**：将搜索的输入、处理、输出合并为完整的搜索流程属性
4. **文件夹管理相关属性**：将文件夹创建、编辑、删除合并为文件夹生命周期属性
5. **编辑模式相关属性**：将编辑模式的进入、操作、退出合并为编辑模式流程属性
6. **性能相关属性**：将多个性能指标合并为综合的性能保证属性
7. **可访问性相关属性**：将多个可访问性功能合并为综合的可访问性支持属性

### 核心正确性属性

#### 属性 1: 应用网格完整性
*对于任何* 已安装的应用程序集合，当 Launcher 打开时，应用网格应正确显示所有应用程序的图标和名称，并保持一致的网格布局。
**验证: 需求 1.1, 1.2, 1.5, 1.7**

#### 属性 2: 应用启动可靠性
*对于任何* 有效的应用程序，当用户点击其图标时，Launcher 应在 2 秒内启动该应用程序，显示适当的动画，并在成功启动后自动关闭。
**验证: 需求 2.1, 2.2, 2.3, 2.7**

#### 属性 3: 搜索功能正确性
*对于任何* 搜索查询和应用程序集合，搜索系统应实时过滤并显示匹配的应用程序，按相关性排序，支持模糊匹配，并正确处理空结果情况。
**验证: 需求 3.2, 3.3, 3.6, 3.8**

#### 属性 4: 文件夹管理一致性
*对于任何* 应用程序对，当用户将一个应用拖到另一个应用上时，系统应创建包含这两个应用的文件夹，支持文件夹的展开、编辑和删除，并保持文件夹内容的完整性。
**验证: 需求 4.1, 4.3, 4.6, 4.7, 4.8**

#### 属性 5: 多页面导航流畅性
*对于任何* 超过单页容量的应用程序集合，页面导航器应正确分页，支持手势、键盘和点击导航，显示平滑的过渡动画和准确的页面指示器。
**验证: 需求 5.1, 5.2, 5.3, 5.5, 5.6, 5.7**

#### 属性 6: 编辑模式安全性
*对于任何* 应用程序集合，当进入编辑模式时，系统应允许重新排列图标，为可删除应用显示删除按钮，保护系统应用，并在退出时保存更改。
**验证: 需求 6.1, 6.3, 6.5, 6.7, 6.10**

#### 属性 7: Launcher 状态切换确定性
*对于任何* Launcher 状态，当用户触发打开/关闭操作（快捷键、Dock点击、ESC键）时，系统应正确切换状态，显示适当的动画，并在指定时间内完成。
**验证: 需求 7.1, 7.2, 7.3, 7.4, 7.7, 7.9**

#### 属性 8: 应用发现实时性
*对于任何* 文件系统变化，系统应实时监控应用程序文件夹，在 5 秒内发现新应用或移除已卸载应用，并更新显示。
**验证: 需求 8.3, 8.4, 8.5, 8.6, 8.9**

#### 属性 9: 键盘导航完整性
*对于任何* 焦点位置，键盘导航应支持箭头键移动焦点、回车键启动应用、TAB键切换焦点区域、ESC键关闭，并保持快速响应。
**验证: 需求 9.2, 9.3, 9.4, 9.6, 9.8**

#### 属性 10: 手势识别准确性
*对于任何* 有效的触控板手势，系统应正确识别捏合打开、滑动手势切换页面，误识别率低于 5%，并在 0.3 秒内响应。
**验证: 需求 10.1, 10.2, 10.5, 10.6**

#### 属性 11: 性能保证
*对于任何* 操作场景，系统应在指定时间内完成：界面渲染 <300ms，搜索过滤 <100ms，图标拖拽响应 <0.1s，保持 60fps 动画，支持至少 500 个应用。
**验证: 需求 11.1, 11.2, 11.3, 11.7, NFR-001**

#### 属性 12: 可访问性支持
*对于任何* 辅助功能设置，系统应支持 VoiceOver 朗读、键盘导航焦点指示、高对比度模式、减少动画效果，并为界面元素提供清晰描述。
**验证: 需求 12.1, 12.2, 12.3, 12.4, 12.6**

#### 属性 13: 设置应用即时性
*对于任何* 设置更改，系统应立即应用无需重启：图标大小、网格尺寸、快捷键、手势启用、外观模式。
**验证: 需求 13.1, 13.2, 13.3, 13.4, 13.5, 14.2**

#### 属性 14: 系统集成一致性
*对于任何* 系统集成操作，Launcher 应与 Dock 和 Mission Control 保持一致的图标资源、状态显示和操作同步。
**验证: 需求 15.1, 15.2, 15.3, 16.1, 16.2**

#### 属性 15: 数据持久化可靠性
*对于任何* 用户布局更改，系统应自动保存数据，在启动时恢复，支持崩溃恢复，系统更新后保持数据，并具有容错能力。
**验证: 需求 17.4, 17.5, 18.1, 18.2, 18.3, 18.4, 18.5**

#### 属性 16: 重置功能完整性
*对于任何* 自定义布局，当用户确认重置时，系统应清除所有自定义设置，重新扫描应用，并按默认顺序排列。
**验证: 需求 19.1, 19.2, 19.3, 19.4, 19.5**

#### 属性 17: 上下文菜单功能性
*对于任何* 应用程序，当用户 Control+点击时，应显示包含打开、显示包内容、获取信息的上下文菜单，并正确执行相应操作。
**验证: 需求 20.1, 20.2, 20.3, 20.4, 20.5, 20.6, 20.7**

#### 属性 18: 边界情况处理
*对于任何* 边界情况（无应用、图标加载失败、全部分类），系统应显示适当的空状态提示、占位图标，并提供刷新功能。
**验证: 需求 21.1, 21.2, 21.3, 21.4, 21.5**

### 属性测试策略

每个属性将通过以下方式验证：

1. **属性测试**: 使用 Swift 的 XCTest 框架结合自定义生成器进行属性测试
2. **单元测试**: 针对具体示例和边界情况
3. **集成测试**: 验证组件间交互
4. **性能测试**: 验证性能属性
5. **UI 测试**: 验证用户交互属性

## 错误处理

### 错误分类

#### 1. 应用相关错误
```swift
enum ApplicationError: Error, Sendable {
    case applicationNotFound(String)
    case applicationLaunchFailed(String, Error)
    case applicationIconLoadFailed(URL)
    case applicationCorrupted(String)
    case insufficientPermissions(String)
    case applicationNotLaunchable(String)
    case sandboxRestriction(String)
}
```

#### 2. 文件系统错误
```swift
enum FileSystemError: Error, Sendable {
    case scanFailed(URL, Error)
    case monitoringFailed(Error)
    case accessDenied(URL)
    case pathNotFound(URL)
    case diskFull
    case fileSystemUnavailable
    case quarantineRestriction(URL)
}
```

#### 3. 用户界面错误
```swift
enum UIError: Error, Sendable {
    case renderingFailed(String)
    case animationFailed(String)
    case layoutCalculationFailed
    case focusManagementFailed
    case gestureRecognitionFailed
    case windowManagementFailed
    case accessibilitySetupFailed
}
```

#### 4. 数据持久化错误
```swift
enum PersistenceError: Error, Sendable {
    case saveFailed(Error)
    case loadFailed(Error)
    case migrationFailed(Int, Int, Error)
    case dataCorruption
    case versionMismatch
    case encryptionFailed
    case decryptionFailed
    case keychainAccessFailed(OSStatus)
}
```

#### 5. 系统集成错误
```swift
enum SystemIntegrationError: Error, Sendable {
    case dockIntegrationFailed(Error)
    case missionControlIntegrationFailed(Error)
    case shortcutRegistrationFailed(Error)
    case gestureRegistrationFailed(Error)
    case accessibilityAPIError(Error)
    case systemAPIUnavailable(String)
}
```

#### 6. 网络和同步错误
```swift
enum NetworkError: Error, Sendable {
    case iCloudSyncFailed(Error)
    case networkUnavailable
    case syncConflict(String)
    case quotaExceeded
}
```

#### 7. 国际化错误
```swift
enum LocalizationError: Error, Sendable {
    case languageNotSupported(AppLanguage)
    case localizationFileMissing(String)
    case pluralizationRuleNotFound(String)
    case stringFormatError(String, [CVarArg])
}
```

### Dock 和 Mission Control 集成设计

#### Dock 集成管理器
```swift
actor DockIntegrationManager: DockIntegrationManagerProtocol {
    private let dockAPI: DockAPIProtocol
    private let settingsManager: SettingsManagerProtocol
    private let eventBus: EventBusProtocol
    
    private var isIntegrationEnabled: Bool = true
    private var dockItems: [DockItem] = []
    
    init(dockAPI: DockAPIProtocol = DockAPI(),
         settingsManager: SettingsManagerProtocol,
         eventBus: EventBusProtocol) {
        self.dockAPI = dockAPI
        self.settingsManager = settingsManager
        self.eventBus = eventBus
    }
    
    func setupIntegration() async throws {
        guard await settingsManager.dockIntegrationEnabled else {
            isIntegrationEnabled = false
            return
        }
        
        do {
            // 1. 获取当前 Dock 状态
            let currentState = try await dockAPI.getCurrentDockState()
            
            // 2. 同步 Launcher 应用状态
            try await syncLauncherApplicationsToDock()
            
            // 3. 监听 Dock 变化
            try await startDockMonitoring()
            
            // 4. 监听应用启动事件
            setupApplicationLaunchMonitoring()
            
            isIntegrationEnabled = true
        } catch {
            isIntegrationEnabled = false
            throw SystemIntegrationError.dockIntegrationFailed(error)
        }
    }
    
    func syncLauncherApplicationsToDock() async throws {
        // 获取 Launcher 中的应用
        // 与 Dock 中的现有项目比较
        // 添加缺失的项目，移除多余的项目
        // 保持位置同步
        
        let launcherApps = await getLauncherApplications()
        let dockState = try await dockAPI.getCurrentDockState()
        
        // 找出需要添加到 Dock 的应用
        let appsToAdd = launcherApps.filter { app in
            !dockState.items.contains { $0.bundleIdentifier == app.bundleIdentifier }
        }
        
        // 添加应用到 Dock
        for app in appsToAdd {
            try await dockAPI.addApplicationToDock(app)
        }
        
        // 更新 Dock 项目位置
        try await updateDockItemPositions()
    }
    
    func handleApplicationLaunched(_ appId: String) async {
        guard isIntegrationEnabled else { return }
        
        // 更新 Dock 中应用的状态指示器
        do {
            try await dockAPI.updateApplicationState(appId, isRunning: true)
            
            // 发布事件
            eventBus.publishApplicationLaunched(appId)
        } catch {
            // 记录错误但不中断流程
            await ErrorLogger.shared.logError(error, severity: .warning, context: ["appId": appId])
        }
    }
    
    func handleApplicationTerminated(_ appId: String) async {
        guard isIntegrationEnabled else { return }
        
        // 更新 Dock 中应用的状态指示器
        do {
            try await dockAPI.updateApplicationState(appId, isRunning: false)
        } catch {
            await ErrorLogger.shared.logError(error, severity: .warning, context: ["appId": appId])
        }
    }
    
    private func startDockMonitoring() async throws {
        // 监听 Dock 变化事件
        try await dockAPI.startMonitoring { [weak self] changes in
            guard let self = self else { return }
            
            Task {
                await self.handleDockChanges(changes)
            }
        }
    }
    
    private func handleDockChanges(_ changes: DockChanges) async {
        // 处理 Dock 变化
        // 1. 更新本地 Dock 项目列表
        // 2. 同步变化到 Launcher
        // 3. 持久化 Dock 状态
        
        dockItems = changes.items
        
        // 发布 Dock 变化事件
        eventBus.publishDockChanged(changes)
        
        // 保存 Dock 状态
        await saveDockState()
    }
    
    private func setupApplicationLaunchMonitoring() {
        // 监听 NSWorkspace 的应用启动/终止通知
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let appInfo = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = appInfo.bundleIdentifier else {
                return
            }
            
            Task {
                await self.handleApplicationLaunched(bundleId)
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let appInfo = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = appInfo.bundleIdentifier else {
                return
            }
            
            Task {
                await self.handleApplicationTerminated(bundleId)
            }
        }
    }
}

protocol DockIntegrationManagerProtocol {
    func setupIntegration() async throws
    func syncLauncherApplicationsToDock() async throws
    func handleApplicationLaunched(_ appId: String) async
    func handleApplicationTerminated(_ appId: String) async
}

protocol DockAPIProtocol {
    func getCurrentDockState() async throws -> DockState
    func addApplicationToDock(_ app: ApplicationInfo) async throws
    func removeApplicationFromDock(_ appId: String) async throws
    func updateApplicationState(_ appId: String, isRunning: Bool) async throws
    func startMonitoring(_ handler: @escaping (DockChanges) -> Void) async throws
}

struct DockState: Sendable {
    let items: [DockItem]
    let configuration: DockConfiguration
}

struct DockChanges: Sendable {
    let items: [DockItem]
    let addedItems: [DockItem]
    let removedItems: [DockItem]
    let movedItems: [(DockItem, Int)]
}
```

#### Mission Control 集成管理器
```swift
actor MissionControlIntegrationManager: MissionControlIntegrationManagerProtocol {
    private let missionControlAPI: MissionControlAPIProtocol
    private let settingsManager: SettingsManagerProtocol
    private let eventBus: EventBusProtocol
    
    private var isIntegrationEnabled: Bool = true
    private var desktopSpaces: [DesktopSpace] = []
    
    init(missionControlAPI: MissionControlAPIProtocol = MissionControlAPI(),
         settingsManager: SettingsManagerProtocol,
         eventBus: EventBusProtocol) {
        self.missionControlAPI = missionControlAPI
        self.settingsManager = settingsManager
        self.eventBus = eventBus
    }
    
    func setupIntegration() async throws {
        guard await settingsManager.missionControlIntegrationEnabled else {
            isIntegrationEnabled = false
            return
        }
        
        do {
            // 1. 获取当前 Mission Control 状态
            let currentState = try await missionControlAPI.getCurrentState()
            
            // 2. 添加 Launcher 到 Mission Control
            try await addLauncherToMissionControl()
            
            // 3. 监听桌面空间变化
            try await startSpaceMonitoring()
            
            // 4. 监听窗口变化
            try await startWindowMonitoring()
            
            isIntegrationEnabled = true
        } catch {
            isIntegrationEnabled = false
            throw SystemIntegrationError.missionControlIntegrationFailed(error)
        }
    }
    
    func addLauncherToMissionControl() async throws {
        // 确保 Launcher 在 Mission Control 中可见
        try await missionControlAPI.setApplicationVisibility(true, for: Constants.launcherBundleIdentifier)
        
        // 设置 Launcher 在 Mission Control 中的显示选项
        let options = MissionControlDisplayOptions(
            showAsWindow: true,
            showThumbnails: true,
            groupWithWindows: false,
            displayOrder: .afterWindows
        )
        
        try await missionControlAPI.setDisplayOptions(options, for: Constants.launcherBundleIdentifier)
    }
    
    func syncApplicationWindows() async throws {
        // 同步应用窗口到 Mission Control
        let runningApps = await getRunningApplications()
        
        for app in runningApps {
            let windows = try await missionControlAPI.getWindows(for: app.bundleIdentifier)
            
            // 更新窗口在 Mission Control 中的显示
            for window in windows {
                let windowInfo = WindowInfo(
                    appId: app.bundleIdentifier,
                    windowId: window.windowId,
                    title: window.title,
                    frame: window.frame,
                    isMinimized: window.isMinimized,
                    isHidden: window.isHidden
                )
                
                try await missionControlAPI.updateWindowInfo(windowInfo)
            }
        }
    }
    
    func handleSpaceChanged(_ spaceId: String) async {
        guard isIntegrationEnabled else { return }
        
        // 更新当前桌面空间
        if let space = desktopSpaces.first(where: { $0.id == spaceId }) {
            // 发布空间变化事件
            eventBus.publishSpaceChanged(space)
            
            // 更新 Launcher 显示（如果需要）
            await updateLauncherForSpace(space)
        }
    }
    
    func handleWindowMoved(_ windowId: String, to spaceId: String) async {
        guard isIntegrationEnabled else { return }
        
        // 更新窗口到桌面空间的映射
        // 持久化窗口位置信息
        // 发布窗口移动事件
        
        eventBus.publishWindowMoved(windowId, to: spaceId)
    }
    
    private func startSpaceMonitoring() async throws {
        // 监听桌面空间变化
        try await missionControlAPI.startSpaceMonitoring { [weak self] spaceChanges in
            guard let self = self else { return }
            
            Task {
                await self.handleSpaceChanges(spaceChanges)
            }
        }
    }
    
    private func startWindowMonitoring() async throws {
        // 监听窗口变化
        try await missionControlAPI.startWindowMonitoring { [weak self] windowChanges in
            guard let self = self else { return }
            
            Task {
                await self.handleWindowChanges(windowChanges)
            }
        }
    }
    
    private func handleSpaceChanges(_ changes: SpaceChanges) async {
        // 更新桌面空间列表
        desktopSpaces = changes.spaces
        
        // 发布空间变化事件
        eventBus.publishSpacesChanged(changes)
        
        // 保存空间配置
        await saveSpaceConfiguration()
    }
    
    private func handleWindowChanges(_ changes: WindowChanges) async {
        // 处理窗口变化
        // 更新窗口状态
        // 同步到 Launcher 显示
        
        eventBus.publishWindowsChanged(changes)
    }
}

protocol MissionControlIntegrationManagerProtocol {
    func setupIntegration() async throws
    func addLauncherToMissionControl() async throws
    func syncApplicationWindows() async throws
    func handleSpaceChanged(_ spaceId: String) async
    func handleWindowMoved(_ windowId: String, to spaceId: String) async
}

protocol MissionControlAPIProtocol {
    func getCurrentState() async throws -> MissionControlState
    func setApplicationVisibility(_ isVisible: Bool, for bundleId: String) async throws
    func setDisplayOptions(_ options: MissionControlDisplayOptions, for bundleId: String) async throws
    func getWindows(for bundleId: String) async throws -> [MissionControlWindow]
    func updateWindowInfo(_ info: WindowInfo) async throws
    func startSpaceMonitoring(_ handler: @escaping (SpaceChanges) -> Void) async throws
    func startWindowMonitoring(_ handler: @escaping (WindowChanges) -> Void) async throws
}

struct MissionControlState: Sendable {
    let spaces: [DesktopSpace]
    let currentSpaceId: String?
    let windows: [MissionControlWindow]
}

struct MissionControlDisplayOptions: Sendable {
    let showAsWindow: Bool
    let showThumbnails: Bool
    let groupWithWindows: Bool
    let displayOrder: DisplayOrder
    
    enum DisplayOrder: Sendable {
        case beforeWindows, afterWindows, withWindows
    }
}

struct MissionControlWindow: Sendable {
    let windowId: String
    let appId: String
    let title: String
    let frame: CGRect
    let isMinimized: Bool
    let isHidden: Bool
}

struct SpaceChanges: Sendable {
    let spaces: [DesktopSpace]
    let addedSpaces: [DesktopSpace]
    let removedSpaces: [DesktopSpace]
}

struct WindowChanges: Sendable {
    let windows: [MissionControlWindow]
    let addedWindows: [MissionControlWindow]
    let removedWindows: [MissionControlWindow]
    let movedWindows: [(MissionControlWindow, String)] // 窗口���新的空间ID
}
```

### 错误处理策略

#### 1. 预防性检查
```swift
class PreventiveChecker {
    func validateApplicationBeforeLaunch(_ app: ApplicationInfo) throws
    func validateGridPosition(_ position: GridPosition) throws
    func validateFolderOperation(_ folder: FolderInfo) throws
    func validateSearchQuery(_ query: String) throws
}
```

#### 2. 优雅降级
```swift
class GracefulDegradation {
    func fallbackToPlaceholderIcon(for app: ApplicationInfo) -> NSImage
    func simplifyAnimationsWhenNeeded() -> Animation
    func reduceGridComplexityWhenSlow() -> GridSize
    func disableNonEssentialFeatures() -> FeatureSet
}
```

#### 3. 错误恢复
```swift
class ErrorRecovery {
    func recoverFromCrash() throws -> UserLayout
    func repairCorruptedData() throws -> Bool
    func reinitializeFailedComponents() throws
    func restoreFromBackup() throws -> UserLayout
}
```

#### 4. 用户通知
```swift
class UserNotifier {
    func showError(_ error: Error, context: String)
    func showWarning(_ message: String, action: (() -> Void)?)
    func showInfo(_ message: String)
    func askForConfirmation(_ question: String) -> Bool
}
```

### 错误日志记录

```swift
class ErrorLogger {
    func logError(_ error: Error, severity: LogSeverity, context: [String: Any])
    func logWarning(_ message: String, context: [String: Any])
    func logInfo(_ message: String, context: [String: Any])
    
    enum LogSeverity {
        case debug, info, warning, error, critical
    }
}
```

## 测试策略

### 测试架构

#### 1. 单元测试层
- **测试目标**: 单个组件、函数、类
- **测试框架**: XCTest
- **覆盖范围**: 业务逻辑、数据模型、工具函数
- **Mock策略**: 使用协议和依赖注入进行模拟

#### 2. 集成测试层
- **测试目标**: 组件间交互、数据流、事件处理
- **测试框架**: XCTest + 自定义测试工具
- **覆盖范围**: 组件集成、事件总线、数据持久化
- **测试数据**: 使用测试专用的数据生成器

#### 3. 属性测试层
- **测试目标**: 正确性属性、不变量、边界条件
- **测试框架**: 自定义属性测试框架（基于 XCTest）
- **覆盖范围**: 所有核心正确性属性
- **生成策略**: 随机生成 + 特定边界值

#### 4. UI 测试层
- **测试目标**: 用户界面、交互、可访问性
- **测试框架**: XCTest UI Testing
- **覆盖范围**: 界面布局、用户交互、辅助功能
- **自动化**: 脚本化用户操作流程

#### 5. 性能测试层
- **测试目标**: 性能指标、响应时间、资源使用
- **测试框架**: XCTest Performance Testing
- **覆盖范围**: 渲染性能、搜索性能、动画性能
- **基准**: 建立性能基准并监控回归

### 属性测试配置

#### 测试库选择
- **主要框架**: XCTest（macOS 原生测试框架）
- **属性测试扩展**: 自定义属性测试工具
- **生成器库**: 自定义随机数据生成器
- **断言库**: XCTest 断言 + 自定义属性断言

#### 测试配置
```swift
struct PropertyTestConfig {
    let minIterations: Int = 100
    let maxIterations: Int = 1000
    let timeout: TimeInterval = 30.0
    let seed: UInt64? = nil // 可选的随机种子用于重现
    let shrinkAttempts: Int = 100 // 收缩尝试次数
}
```

#### 测试标签格式
```swift
// 属性测试标签格式
// 功能: {功能名称}, 属性 {编号}: {属性描述}
// 示例: 功能: macos-launcher, 属性 1: 应用网格完整性
```

### 测试数据管理

#### 测试数据生成
```swift
protocol TestDataGenerator {
    func generateApplications(count: Int) -> [ApplicationInfo]
    func generateSearchQueries(count: Int) -> [String]
    func generateUserLayouts(count: Int) -> [UserLayout]
    func generateFolderStructures(count: Int) -> [FolderInfo]
    func generateEdgeCases() -> [EdgeCase]
}
```

#### 测试数据验证
```swift
protocol TestDataValidator {
    func validateTestData(_ data: Any) throws
    func ensureTestCoverage() -> CoverageReport
    func detectRedundantTests() -> [String]
    func suggestAdditionalTests() -> [TestSuggestion]
}
```

### 测试执行策略

#### 测试套件组织
```swift
struct TestSuiteOrganization {
    // 按功能模块组织
    let applicationTests: [XCTestCase]
    let searchTests: [XCTestCase]
    let folderTests: [XCTestCase]
    let navigationTests: [XCTestCase]
    let performanceTests: [XCTestCase]
    let accessibilityTests: [XCTestCase]
    
    // 按测试类型组织
    let unitTests: [XCTestCase]
    let integrationTests: [XCTestCase]
    let propertyTests: [XCTestCase]
    let uiTests: [XCTestCase]
}
```

#### 测试执行计划
```swift
struct TestExecutionPlan {
    // 开发阶段
    let preCommitTests: [XCTestCase] // 快速测试，每次提交前运行
    let dailyTests: [XCTestCase]     // 完整测试，每日运行
    let weeklyTests: [XCTestCase]    // 深度测试，每周运行
    
    // CI/CD 管道
    let buildPipelineTests: [XCTestCase]
    let deploymentTests: [XCTestCase]
    
    // 发布阶段
    let releaseCandidateTests: [XCTestCase]
    let productionTests: [XCTestCase]
}
```

### 测试质量保证

#### 测试覆盖率目标
```swift
struct TestCoverageGoals {
    let lineCoverage: Double = 0.85      // 85% 行覆盖率
    let branchCoverage: Double = 0.80    // 80% 分支覆盖率
    let functionCoverage: Double = 0.90  // 90% 函数覆盖率
    let propertyCoverage: Double = 1.0   // 100% 属性覆盖率
}
```

#### 测试质量指标
```swift
struct TestQualityMetrics {
    let flakyTestRate: Double           // 不稳定测试率
    let falsePositiveRate: Double       // 误报率
    let falseNegativeRate: Double       // 漏报率
    let testExecutionTime: TimeInterval // 测试执行时间
    let testMaintenanceCost: Double     // 测试维护成本
}
```

### 持续测试集成

#### CI/CD 集成
```swift
struct CICDIntegration {
    let triggerOnPush: Bool = true
    let triggerOnPR: Bool = true
    let runParallelTests: Bool = true
    let cacheTestResults: Bool = true
    let reportTestResults: Bool = true
    
    func configureForPlatform(_ platform: CICDPlatform)
}
```

#### 测试报告
```swift
struct TestReport {
    let summary: TestSummary
    let details: [TestDetail]
    let coverage: CoverageReport
    let performance: PerformanceReport
    let recommendations: [Recommendation]
    
    func generateHTMLReport() -> String
    func generateJSONReport() -> Data
    func sendToMonitoringSystem()
}
```

### 测试维护策略

#### 测试重构
```swift
protocol TestRefactoring {
    func removeDuplicateTests()
    func simplifyComplexTests()
    func improveTestReadability()
    func updateTestsForAPIChanges()
}
```

#### 测试文档
```swift
struct TestDocumentation {
    let testPurpose: String
    let testStrategy: String
    let testData: String
    let expectedResults: String
    let knownIssues: String
    let maintenanceNotes: String
}
```

这个测试策略确保了全面的测试覆盖，包括单元测试、集成测试、属性测试和UI测试，同时关注性能、可访问性和错误处理。属性测试特别重要，因为它们验证了系统的核心正确性属性，而不仅仅是特定的示例。