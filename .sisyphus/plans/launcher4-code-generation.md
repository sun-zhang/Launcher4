# Launcher4 代码生成计划

## TL;DR

> **Quick Summary**: 基于 `.specs` 目录的完整规范文档，参考 LaunchNext2 成熟实现，使用 TDD 方式从零构建 macOS Launchpad 风格的应用启动器核心功能。
> 
> **Deliverables**: 
> - 完整的 macOS Launcher 应用
> - 60+ 个 Swift 源文件 (Models, Services, ViewModels, Views, Utilities)
> - 单元测试覆盖核心业务逻辑
> - 双渲染模式 (SwiftUI + Core Animation)
> 
> **Estimated Effort**: Large (约 40-60 任务)
> **Parallel Execution**: YES - 8 waves
> **Critical Path**: Models → Services → ViewModels → Views → Integration

---

## Context

### Original Request
根据项目目录中的 `.specs` 目录需求、设计和任务文档，参考 LaunchNext2 项目的核心代码，生成 Launcher4 的代码生成计划。

### Interview Summary

**Key Discussions**:
- **功能范围**: 仅核心功能（应用网格、搜索、文件夹、多页面、编辑模式、设置），不包括高级功能（原生导入、声音、语音、游戏手柄）
- **渲染方案**: 混合模式 - SwiftUI 网格 + Core Animation CAGridView 双模式，支持性能切换
- **存储方案**: Core Data + UserDefaults（按设计文档），而非 LaunchNext2 的 SwiftData
- **测试策略**: TDD（测试驱动开发）- 每个 TODO 包含测试用例

**Research Findings**:
- **LaunchNext2**: 成熟的 Launchpad 替代应用，25 个核心 Swift 文件，可作为实现参考
- **.specs 文档**: 完整的需求 (21 个功能需求 + 8 个非功能性需求)、设计 (MVVM + Actor 架构)、任务 (19 个主要任务)
- **当前状态**: 仅有 Xcode 模板文件，实际代码需从头实现

### Metis Review
**Identified Gaps** (addressed):
- Gap 1: 需明确测试框架选择 → 默认使用 XCTest
- Gap 2: Core Data 模型版本迁移策略 → 初版无需迁移，预留迁移接口
- Gap 3: 全局快捷键实现方案 → 参考 LaunchNext2 使用 Carbon API
- Gap 4: CAGridView 复杂度 → 可先实现 SwiftUI 版本，后续优化添加 CA 版本

---

## Work Objectives

### Core Objective
基于 `.specs` 规范文档，参考 LaunchNext2 的实现模式，使用 TDD 方式从零构建一个功能完整、性能优良、符合 macOS HIG 的应用启动器。

### Concrete Deliverables
- **数据层**: 10+ Sendable 数据模型 + Core Data 持久化
- **服务层**: 8+ Actor 服务（应用扫描、文件夹管理、设置管理等）
- **ViewModel 层**: 5+ @MainActor 视图模型
- **视图层**: 10+ SwiftUI 视图（主界面、搜索、文件夹、设置等）
- **高性能网格**: CAGridView + NSViewRepresentable 桥接
- **系统集成**: 全局快捷键、触控板手势、窗口管理

### Definition of Done
- [ ] 所有核心需求 (R1-R21) 的验收标准通过
- [ ] 所有非功能性需求 (NFR-001 ~ NFR-008) 达标
- [ ] 单元测试覆盖率 ≥ 80% (核心业务逻辑)
- [ ] 性能指标达标：冷启动 <500ms，搜索 <100ms，动画 60fps

### Must Have
- 应用网格展示与启动
- 实时搜索功能
- 文件夹创建与管理
- 多页面导航
- 编辑模式（拖拽重排、删除）
- 设置界面
- 数据持久化
- 双渲染模式支持

### Must NOT Have (Guardrails)
- ❌ 原生 Launchpad 数据库导入
- ❌ 声音效果系统
- ❌ 语音反馈功能
- ❌ 游戏手柄支持
- ❌ Dock/Mission Control 深度集成
- ❌ 云同步功能
- ❌ 主题/插件系统
- ❌ 过度工程化（如不必要的抽象层）

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: NO (需创建)
- **Automated tests**: YES (TDD)
- **Framework**: XCTest
- **TDD Workflow**: RED (failing test) → GREEN (minimal impl) → REFACTOR

### QA Policy
Every task includes agent-executed QA scenarios with evidence saved to `.sisyphus/evidence/`.

- **UI Views**: Use Playwright — Navigate, interact, assert DOM, screenshot
- **macOS Native**: Use Bash — Run app, verify window state, check logs
- **Core Logic**: Use XCTest — Run tests, assert coverage

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation - 项目基础):
├── Task 1: 项目结构配置与目录创建 [quick]
├── Task 2: Core Data 模型定义 [deep]
├── Task 3: Sendable 数据模型实现 [quick]
├── Task 4: 协议定义 (所有 Protocol) [quick]
├── Task 5: DIContainer 依赖注入容器 [quick]
└── Task 6: EventBus 事件总线 [quick]

Wave 2 (Services Layer - 服务层 Actors):
├── Task 7: ApplicationScanner Actor [deep]
├── Task 8: FolderManager Actor [deep]
├── Task 9: SettingsManager Actor [quick]
├── Task 10: IconCache Actor [quick]
├── Task 11: LauncherStateManager Actor [deep]
└── Task 12: KeyboardShortcutManager Actor [quick]

Wave 3 (ViewModels - 视图模型 @MainActor):
├── Task 13: ApplicationGridViewModel [deep]
├── Task 14: SearchViewModel [quick]
├── Task 15: PageNavigator [quick]
├── Task 16: ContextMenuManager [quick]
└── Task 17: AccessibilityManager [quick]

Wave 4 (High Performance Grid - 高性能网格):
├── Task 18: CAGridView (Core Animation) [deep]
├── Task 19: CAGridView+Layout [deep]
├── Task 20: CAGridView+Input [deep]
├── Task 21: CAGridViewRepresentable (SwiftUI Bridge) [quick]
└── Task 22: PerformanceMode 切换逻辑 [quick]

Wave 5 (UI Components - SwiftUI 视图):
├── Task 23: LauncherApp 主应用入口 [quick]
├── Task 24: LaunchpadView 主界面 [visual-engineering]
├── Task 25: ApplicationIconView 图标组件 [quick]
├── Task 26: FolderView 文件夹视图 [quick]
├── Task 27: SearchView 搜索界面 [quick]
├── Task 28: PageIndicatorView 页面指示器 [quick]
├── Task 29: SettingsView 设置界面 [visual-engineering]
└── Task 30: EditModeOverlay 编辑模式覆盖层 [quick]

Wave 6 (System Integration - 系统集成):
├── Task 31: GestureManager 触控板手势 [deep]
├── Task 32: AnimationManager 动画管理 [quick]
├── Task 33: WindowController 窗口控制 [deep]
└── Task 34: LocalizationManager 国际化 [quick]

Wave 7 (Tests & Polish - 测试与优化):
├── Task 35: 单元测试补充 [deep]
├── Task 36: 性能优化与内存管理 [deep]
├── Task 37: 可访问性支持完善 [quick]
└── Task 38: 边界情况处理 [quick]

Wave 8 (Final Integration - 最终集成):
├── Task 39: 组件连接与依赖注入配置 [deep]
├── Task 40: 端到端测试 [deep]
├── Task 41: 性能基准验证 [quick]
└── Task 42: 文档与代码注释 [writing]

Critical Path: T1-T6 → T7-T12 → T13-T17 → T18-T22 → T23-T30 → T31-T34 → T35-T38 → T39-T42
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 6 (Waves 1 & 2)
```

### Dependency Matrix

- **1-6**: — — 7-17, 1
- **7-12**: 1-6 — 13-17, 2
- **13-17**: 1-12 — 23-30, 3
- **18-22**: 13-17 — 24, 4
- **23-30**: 13-22 — 31-34, 5
- **31-34**: 23-30 — 35-38, 6
- **35-38**: 23-34 — 39-42, 7
- **39-42**: 1-38 — —, FINAL

### Agent Dispatch Summary

- **Wave 1**: **6** tasks — T1-T4 → `quick`, T5-T6 → `quick`
- **Wave 2**: **6** tasks — T7,T8,T11 → `deep`, T9,T10,T12 → `quick`
- **Wave 3**: **5** tasks — T13 → `deep`, T14-T17 → `quick`
- **Wave 4**: **5** tasks — T18-T20 → `deep`, T21-T22 → `quick`
- **Wave 5**: **8** tasks — T24,T29 → `visual-engineering`, others → `quick`
- **Wave 6**: **4** tasks — T31,T33 → `deep`, T32,T34 → `quick`
- **Wave 7**: **4** tasks — T35,T36 → `deep`, T37,T38 → `quick`
- **Wave 8**: **4** tasks — T39,T40 → `deep`, T41 → `quick`, T42 → `writing`

---

## TODOs

### Wave 1: Foundation (项目基础)

- [x] 1. 项目结构配置与目录创建

  **What to do**:
  - 创建标准目录结构：`Models/`, `Services/`, `ViewModels/`, `Views/`, `Protocols/`, `Utilities/`, `Resources/`
  - 配置 Info.plist 权限（App Sandbox, 文件访问等）
  - 创建 Core Data 模型文件 `Launcher4.xcdatamodeld`
  - 设置本地化目录 `en.lproj/`, `zh-Hans.lproj/`

  **Must NOT do**:
  - 不要创建不需要的目录（如 `Tests/` 单独目录，测试文件放主 target）
  - 不要配置 SwiftData（使用 Core Data）

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 2-6
  - **Blocked By**: None

  **References**:
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/` - 参考 LaunchNext2 的文件组织结构
  - `.specs/design.md:38-67` - 架构分层设计

  **Acceptance Criteria**:
  - [ ] 目录结构创建完成
  - [ ] Xcode 项目能成功编译
  - [ ] Core Data 模型文件创建

  **QA Scenarios**:
  ```
  Scenario: 项目结构验证
    Tool: Bash
    Steps:
      1. ls -la Launcher4/Models Launcher4/Services Launcher4/ViewModels Launcher4/Views
      2. xcodebuild -project Launcher4.xcodeproj -scheme Launcher4 -configuration Debug build
    Expected Result: 目录存在，构建成功 (exit code 0)
    Evidence: .sisyphus/evidence/task-01-structure.txt
  ```

  **Commit**: YES
  - Message: `feat(core): add project structure and directories`
  - Files: `Launcher4.xcodeproj`, new directories

- [x] 2. Core Data 模型定义

  **What to do**:
  - 定义 `ApplicationEntity` 实体（id, name, bundleIdentifier, bundleURL, position, page）
  - 定义 `FolderEntity` 实体（id, name, applications, creationDate）
  - 定义 `SettingsEntity` 实体（key, value）
  - 配置实体关系和索引

  **Must NOT do**:
  - 不要使用 SwiftData 宏（@Model）
  - 不要定义过多实体（保持简洁）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 7, 8, 9
  - **Blocked By**: Task 1

  **References**:
  - `.specs/design.md:577-726` - 数据模型定义
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/AppInfo.swift` - 参考应用信息结构

  **Acceptance Criteria**:
  - [ ] Core Data 模型包含 3 个实体
  - [ ] 实体属性完整定义
  - [ ] 模型编译无错误

  **QA Scenarios**:
  ```
  Scenario: Core Data 模型验证
    Tool: Bash
    Steps:
      1. xcodebuild build 验证模型编译
      2. 检查 .xcdatamodeld 文件存在
    Expected Result: 构建成功，模型文件存在
    Evidence: .sisyphus/evidence/task-02-coredata.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [x] 3. Sendable 数据模型实现

  **What to do**:
  - 创建 `ApplicationInfo` 结构体（实现 Sendable, Codable, Identifiable）
  - 创建 `GridPosition` 和 `GridSize` 结构体
  - 创建 `FolderInfo` 结构体
  - 创建 `AppSettings` 结构体
  - 创建 `LocalizedString` 结构体（国际化支持）

  **Must NOT do**:
  - 不要使用 class（必须使用 struct）
  - 不要添加非 Sendable 属性

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 7-17
  - **Blocked By**: Task 1

  **References**:
  - `.specs/design.md:577-726` - 数据模型详细定义
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/AppInfo.swift` - 参考 AppInfo 结构
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/FolderInfo.swift` - 参考 FolderInfo 结构

  **Acceptance Criteria**:
  - [ ] 所有结构体实现 Sendable 协议
  - [ ] 单元测试覆盖初始化和编解码
  - [ ] 编译无警告

  **QA Scenarios**:
  ```
  Scenario: 数据模型测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/ModelTests
    Expected Result: 所有测试通过
    Evidence: .sisyphus/evidence/task-03-models.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [x] 4. 协议定义 (所有 Protocol)

  **What to do**:
  - 创建 `ApplicationScannerProtocol`
  - 创建 `FolderManagerProtocol`
  - 创建 `SettingsManagerProtocol`
  - 创建 `EventBusProtocol`
  - 创建 `IconCacheProtocol`
  - 创建 `LauncherStateManagerProtocol`

  **Must NOT do**:
  - 不要在协议中包含实现代码
  - 不要定义过多方法（保持接口精简）

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 7-12
  - **Blocked By**: Task 1

  **References**:
  - `.specs/design.md:71-398` - 组件接口定义
  - `.specs/design.md:400-505` - EventBus 协议定义

  **Acceptance Criteria**:
  - [ ] 所有核心协议定义完成
  - [ ] 协议方法签名正确
  - [ ] 编译无错误

  **QA Scenarios**:
  ```
  Scenario: 协议编译验证
    Tool: Bash
    Steps:
      1. xcodebuild build 验证协议编译
    Expected Result: 构建成功
    Evidence: .sisyphus/evidence/task-04-protocols.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [x] 5. DIContainer 依赖注入容器

  **What to do**:
  - 实现 `DIContainer` 类（单例模式）
  - 支持 `register()` 和 `resolve()` 方法
  - 支持三种作用域：singleton, transient, scoped
  - 配置默认依赖关系

  **Must NOT do**:
  - 不要使用第三方 DI 框架
  - 不要过度复杂化（保持简洁）

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 7-42 (所有依赖注入的任务)
  - **Blocked By**: Task 1

  **References**:
  - `.specs/design.md:371-397` - DIContainer 设计
  - `.specs/design.md:507-569` - 依赖注入配置

  **Acceptance Criteria**:
  - [ ] DIContainer 支持三种作用域
  - [ ] 单元测试覆盖注册和解析
  - [ ] 线程安全实现

  **QA Scenarios**:
  ```
  Scenario: DI 容器测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/DIContainerTests
    Expected Result: resolve 返回正确实例
    Evidence: .sisyphus/evidence/task-05-di.txt
  ```

  **Commit**: NO (groups with Wave 1)

- [x] 6. EventBus 事件总线

  **What to do**:
  - 实现 `EventBus` 类（遵循 EventBusProtocol）
  - 使用 Combine 的 PassthroughSubject 实现发布/订阅
  - 定义所有事件类型：applicationAdded, applicationRemoved, editModeChanged 等
  - 确保线程安全

  **Must NOT do**:
  - 不要使用 NotificationCenter（使用 Combine）
  - 不要泄漏订阅者

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: Tasks 7-42 (所有需要事件通信的任务)
  - **Blocked By**: Task 1

  **References**:
  - `.specs/design.md:400-505` - EventBus 设计
  - `.specs/design.md:571-577` - 数据流设计

  **Acceptance Criteria**:
  - [ ] 所有事件类型定义完成
  - [ ] 发布/订阅机制正常工作
  - [ ] 线程安全实现

  **QA Scenarios**:
  ```
  Scenario: 事件总线测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/EventBusTests
    Expected Result: 订阅者收到事件
    Evidence: .sisyphus/evidence/task-06-eventbus.txt
  ```

  **Commit**: YES
  - Message: `feat(core): add DI container and event bus`
  - Files: `DIContainer.swift`, `EventBus.swift`, all Wave 1 files

### Wave 2: Services Layer (服务层 Actors)

- [x] 7. ApplicationScanner Actor

  **What to do**:
  - 实现 `ApplicationScanner` actor（遵循 ApplicationScannerProtocol）
  - 使用 Launch Services API 扫描 `/Applications`, `~/Applications`
  - 实现 FSEvents 文件系统监控
  - 提取应用元数据（名称、图标、Bundle ID）
  - 实现后台扫描队列

  **Must NOT do**:
  - 不要在主线程执行扫描
  - 不要缓存过期数据

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 13, 14
  - **Blocked By**: Tasks 1-4

  **References**:
  - `.specs/design.md:71-94` - ApplicationScanner 设计
  - `.specs/requirements.md:134-149` - 应用发现需求 R8
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/AppStore.swift` - 参考扫描实现

  **Acceptance Criteria**:
  - [ ] 扫描标准应用目录成功
  - [ ] FSEvents 监控正常工作
  - [ ] 应用变更事件正确发布
  - [ ] 单元测试覆盖扫描逻辑

  **QA Scenarios**:
  ```
  Scenario: 应用扫描测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/ApplicationScannerTests
    Expected Result: 扫描返回应用列表，FSEvents 回调正常
    Evidence: .sisyphus/evidence/task-07-scanner.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 8. FolderManager Actor

  **What to do**:
  - 实现 `FolderManager` actor（遵循 FolderManagerProtocol）
  - 实现文件夹创建、编辑、删除逻辑
  - 实现文件夹图标生成（组合内部应用图标）
  - 处理文件夹内容管理（添加/移除应用）
  - 与 Core Data 集成持久化

  **Must NOT do**:
  - 不要支持文件夹嵌套（按需求约束）
  - 不要允许空文件夹存在

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 13, 26
  - **Blocked By**: Tasks 2, 4

  **References**:
  - `.specs/design.md:137-159` - FolderManager 设计
  - `.specs/requirements.md:67-83` - 文件夹管理需求 R4
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/FolderInfo.swift` - 参考文件夹实现

  **Acceptance Criteria**:
  - [ ] 文件夹 CRUD 操作正常
  - [ ] 文件夹图标正确生成
  - [ ] 单一应用时自动删除文件夹
  - [ ] 单元测试覆盖文件夹逻辑

  **QA Scenarios**:
  ```
  Scenario: 文件夹管理测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/FolderManagerTests
    Expected Result: 创建/删除/重命名正常，图标生成正确
    Evidence: .sisyphus/evidence/task-08-folder.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 9. SettingsManager Actor

  **What to do**:
  - 实现 `SettingsManager` actor（遵循 SettingsManagerProtocol）
  - 管理图标大小、网格尺寸、快捷键、外观模式等设置
  - 使用 UserDefaults 持久化
  - 支持设置导入/导出

  **Must NOT do**:
  - 不要使用 Keychain 存储非敏感设置
  - 不要阻塞主线程

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 15, 29
  - **Blocked By**: Tasks 4

  **References**:
  - `.specs/design.md:179-215` - SettingsManager 设计
  - `.specs/requirements.md:206-217` - 个性化设置需求 R13

  **Acceptance Criteria**:
  - [ ] 所有设置项正确存储和读取
  - [ ] 设置变更立即生效
  - [ ] 单元测试覆盖设置逻辑

  **QA Scenarios**:
  ```
  Scenario: 设置管理测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/SettingsManagerTests
    Expected Result: 设置保存/读取正确
    Evidence: .sisyphus/evidence/task-09-settings.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 10. IconCache Actor

  **What to do**:
  - 实现 `IconCache` actor（遵循 IconCacheProtocol）
  - 使用 NSCache 实现内存缓存
  - 支持磁盘缓存（可选）
  - 实现图标预加载
  - 处理内存警告清理

  **Must NOT do**:
  - 不要缓存过多（内存限制 50MB）
  - 不要阻塞主线程加载图标

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 13, 18, 25
  - **Blocked By**: Tasks 4

  **References**:
  - `.specs/design.md:1221-1356` - 图标缓存设计
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/IconStore.swift` - 参考图标缓存实现

  **Acceptance Criteria**:
  - [ ] 图标缓存命中率 > 90%
  - [ ] 内存使用在限制范围内
  - [ ] 单元测试覆盖缓存逻辑

  **QA Scenarios**:
  ```
  Scenario: 图标缓存测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/IconCacheTests
    Expected Result: 缓存命中，内存不超限
    Evidence: .sisyphus/evidence/task-10-cache.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 11. LauncherStateManager Actor

  **What to do**:
  - 实现 `LauncherStateManager` actor
  - 管理窗口显示/隐藏状态
  - 控制打开/关闭动画（淡入淡出、缩放）
  - 处理背景模糊效果
  - 集成 NSWindow 管理

  **Must NOT do**:
  - 不要在动画未完成时响应新操作
  - 不要阻塞主线程

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: Tasks 23, 33
  - **Blocked By**: Tasks 4

  **References**:
  - `.specs/design.md:217-235` - LauncherStateManager 设计
  - `.specs/requirements.md:119-133` - Launcher 显示与隐藏需求 R7
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/LaunchpadApp.swift` - 参考窗口管理

  **Acceptance Criteria**:
  - [ ] 窗口显示/隐藏动画流畅
  - [ ] 状态跟踪准确
  - [ ] 背景模糊效果正常
  - [ ] 单元测试覆盖状态管理

  **QA Scenarios**:
  ```
  Scenario: 状态管理测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/LauncherStateManagerTests
    Expected Result: 显示/隐藏状态正确切换
    Evidence: .sisyphus/evidence/task-11-state.txt
  ```

  **Commit**: NO (groups with Wave 2)

- [x] 12. KeyboardShortcutManager Actor

  **What to do**:
  - 实现 `KeyboardShortcutManager` actor
  - 使用 Carbon API 注册全局热键（F4/Fn+F4）
  - 处理热键回调
  - 支持快捷键自定义
  - 处理快捷键冲突

  **Must NOT do**:
  - 不要使用 NSEvent addGlobalMonitorForEvents（权限问题）
  - 不要阻塞热键回调

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 23
  - **Blocked By**: Tasks 4, 9

  **References**:
  - `.specs/design.md:237-257` - KeyboardShortcutManager 设计
  - `.specs/requirements.md:152-165` - 键盘快捷键需求 R9
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/LaunchpadApp.swift` - 参考 Carbon API 使用

  **Acceptance Criteria**:
  - [ ] 全局热键注册成功
  - [ ] 热键回调正常触发
  - [ ] 支持快捷键自定义
  - [ ] 单元测试覆盖热键逻辑

  **QA Scenarios**:
  ```
  Scenario: 快捷键测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/KeyboardShortcutManagerTests
    Expected Result: 热键注册和回调正常
    Evidence: .sisyphus/evidence/task-12-shortcut.txt
  ```

  **Commit**: YES
  - Message: `feat(services): add service layer actors`
  - Files: `ApplicationScanner.swift`, `FolderManager.swift`, `SettingsManager.swift`, `IconCache.swift`, `LauncherStateManager.swift`, `KeyboardShortcutManager.swift`

### Wave 3: ViewModels (视图模型 @MainActor)

- [x] 13. ApplicationGridViewModel

  **What to do**:
  - 实现 `ApplicationGridViewModel` 类（@MainActor, ObservableObject）
  - 管理应用网格显示逻辑和状态
  - 支持编辑模式和图标拖拽
  - 处理应用启动和删除
  - 集成文件夹创建流程

  **Must NOT do**:
  - 不要在 ViewModel 中直接操作 UI
  - 不要阻塞主线程

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 24, 25, 30
  - **Blocked By**: Tasks 3, 7, 8, 10

  **References**:
  - `.specs/design.md:95-117` - ApplicationGridViewModel 设计
  - `.specs/requirements.md:21-36` - 应用网格展示需求 R1
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/AppStore.swift` - 参考状态管理

  **Acceptance Criteria**:
  - [ ] 应用列表正确显示
  - [ ] 编辑模式切换正常
  - [ ] 拖拽重排功能正常
  - [ ] 单元测试覆盖 ViewModel 逻辑

  **QA Scenarios**:
  ```
  Scenario: 网格 ViewModel 测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/ApplicationGridViewModelTests
    Expected Result: 应用列表、编辑模式、拖拽功能正常
    Evidence: .sisyphus/evidence/task-13-gridvm.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 14. SearchViewModel

  **What to do**:
  - 实现 `SearchViewModel` 类（@MainActor, ObservableObject）
  - 管理搜索功能和实时过滤
  - 支持模糊匹配（不区分大小写）
  - 处理搜索结果排序（按匹配度）
  - 集成搜索历史（可选）

  **Must NOT do**:
  - 不要在每次按键时立即搜索（需要防抖 50ms）
  - 不要搜索隐藏的应用（除非明确指定）

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: Task 27
  - **Blocked By**: Tasks 3, 7

  **References**:
  - `.specs/design.md:118-136` - SearchViewModel 设计
  - `.specs/requirements.md:52-66` - 搜索需求 R3

  **Acceptance Criteria**:
  - [ ] 搜索结果正确过滤
  - [ ] 搜索响应 < 100ms
  - [ ] 支持中英文搜索
  - [ ] 单元测试覆盖搜索逻辑

  **QA Scenarios**:
  ```
  Scenario: 搜索 ViewModel 测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/SearchViewModelTests
    Expected Result: 搜索过滤正确，响应时间 < 100ms
    Evidence: .sisyphus/evidence/task-14-searchvm.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 15. PageNavigator

  **What to do**:
  - 实现 `PageNavigator` 类（@MainActor, ObservableObject）
  - 管理多页面导航和页面切换
  - 计算总页数和当前页应用
  - 支持页面指示器更新

  **Must NOT do**:
  - 不要在页面边界外导航
  - 不要忽略动画完成状态

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 24, 28
  - **Blocked By**: Tasks 3, 9

  **References**:
  - `.specs/design.md:161-178` - PageNavigator 设计
  - `.specs/requirements.md:84-100` - 多页面导航需求 R5

  **Acceptance Criteria**:
  - [ ] 页面切换正常
  - [ ] 页面指示器正确更新
  - [ ] 单元测试覆盖导航逻辑

  **QA Scenarios**:
  ```
  Scenario: 页面导航测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/PageNavigatorTests
    Expected Result: 页面切换和指示器更新正确
    Evidence: .sisyphus/evidence/task-15-pagenav.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 16. ContextMenuManager

  **What to do**:
  - 实现 `ContextMenuManager` 类（@MainActor）
  - 创建应用图标的上下文菜单（打开、显示包内容、获取信息）
  - 创建文件夹的上下文菜单（重命名、删除）
  - 处理菜单项点击事件

  **Must NOT do**:
  - 不要为系统应用显示删除选项
  - 不要阻塞菜单显示

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 24, 25, 26
  - **Blocked By**: Task 3

  **References**:
  - `.specs/design.md:287-304` - ContextMenuManager 设计
  - `.specs/requirements.md:290-303` - 上下文菜单需求 R20

  **Acceptance Criteria**:
  - [ ] 上下文菜单正确显示
  - [ ] 菜单项点击正常响应
  - [ ] 单元测试覆盖菜单逻辑

  **QA Scenarios**:
  ```
  Scenario: 上下文菜单测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/ContextMenuManagerTests
    Expected Result: 菜单项正确显示和响应
    Evidence: .sisyphus/evidence/task-16-context.txt
  ```

  **Commit**: NO (groups with Wave 3)

- [x] 17. AccessibilityManager

  **What to do**:
  - 实现 `AccessibilityManager` 类（@MainActor）
  - 设置 VoiceOver 支持标签
  - 实现键盘导航辅助
  - 支持高对比度模式
  - 处理减少动画效果选项

  **Must NOT do**:
  - 不要忽略系统辅助功能设置
  - 不要使用仅视觉的反馈

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: Tasks 24, 37
  - **Blocked By**: Task 3

  **References**:
  - `.specs/design.md:354-368` - AccessibilityManager 设计
  - `.specs/requirements.md:194-205` - 可访问性需求 R12

  **Acceptance Criteria**:
  - [ ] VoiceOver 标签正确设置
  - [ ] 键盘导航正常工作
  - [ ] 高对比度模式支持
  - [ ] 单元测试覆盖可访问性逻辑

  **QA Scenarios**:
  ```
  Scenario: 可访问性测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/AccessibilityManagerTests
    Expected Result: VoiceOver 标签、键盘导航正常
    Evidence: .sisyphus/evidence/task-17-access.txt
  ```

  **Commit**: YES
  - Message: `feat(viewmodels): add view models`
  - Files: `ApplicationGridViewModel.swift`, `SearchViewModel.swift`, `PageNavigator.swift`, `ContextMenuManager.swift`, `AccessibilityManager.swift`

### Wave 4: High Performance Grid (高性能网格)

- [ ] 18. CAGridView (Core Animation)

  **What to do**:
  - 实现 `CAGridView` 类（继承 NSView）
  - 创建 CALayer 层次结构
  - 实现 CADisplayLink 支持 120Hz
  - 实现图标缓存（CGImage）
  - 支持流畅滚动动画

  **Must NOT do**:
  - 不要在主线程执行繁重操作
  - 不要创建过多图层（按需创建）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4
  - **Blocks**: Tasks 21, 22
  - **Blocked By**: Tasks 10, 13

  **References**:
  - `.specs/design.md:182-213` - CAGridView 设计（参考 LaunchNext2）
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/CAGridView.swift` - 完整 CAGridView 实现
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/CAGridView+Layout.swift` - 布局扩展
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/CAGridView+Input.swift` - 输入处理扩展

  **Acceptance Criteria**:
  - [ ] 支持 120Hz ProMotion
  - [ ] 滚动帧率稳定 60fps+
  - [ ] 图标缓存正常工作
  - [ ] 单元测试覆盖核心功能

  **QA Scenarios**:
  ```
  Scenario: CA Grid 性能测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/CAGridViewTests
    Expected Result: 帧率 ≥ 60fps，内存使用正常
    Evidence: .sisyphus/evidence/task-18-cagrid.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [ ] 19. CAGridView+Layout

  **What to do**:
  - 实现网格布局计算逻辑
  - 计算图标位置和大小
  - 处理页面布局
  - 支持不同网格尺寸

  **Must NOT do**:
  - 不要频繁重算布局（使用缓存）
  - 不要在滚动时改变布局

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4
  - **Blocks**: Task 21
  - **Blocked By**: Task 18

  **References**:
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/CAGridView+Layout.swift` - 布局实现参考

  **Acceptance Criteria**:
  - [ ] 布局计算正确
  - [ ] 支持不同网格尺寸
  - [ ] 性能满足要求

  **QA Scenarios**:
  ```
  Scenario: 布局计算测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/CAGridViewLayoutTests
    Expected Result: 布局位置正确
    Evidence: .sisyphus/evidence/task-19-layout.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [ ] 20. CAGridView+Input

  **What to do**:
  - 实现鼠标点击处理
  - 实现拖拽操作
  - 实现滚轮滚动
  - 实现悬停效果

  **Must NOT do**:
  - 不要在动画中响应输入
  - 不要丢失点击事件

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4
  - **Blocks**: Task 21
  - **Blocked By**: Task 18

  **References**:
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/CAGridView+Input.swift` - 输入处理参考

  **Acceptance Criteria**:
  - [ ] 点击响应正确
  - [ ] 拖拽操作正常
  - [ ] 滚动流畅

  **QA Scenarios**:
  ```
  Scenario: 输入处理测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/CAGridViewInputTests
    Expected Result: 点击、拖拽、滚动正常
    Evidence: .sisyphus/evidence/task-20-input.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [ ] 21. CAGridViewRepresentable (SwiftUI Bridge)

  **What to do**:
  - 实现 `CAGridViewRepresentable` 结构体（遵循 NSViewRepresentable）
  - 在 `makeNSView()` 中创建 CAGridView
  - 在 `updateNSView()` 中更新配置
  - 协调事件到 ViewModel

  **Must NOT do**:
  - 不要在 Representable 中存储状态
  - 不要阻塞 SwiftUI 更新

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 18, 19, 20

  **References**:
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/CAGridViewRepresentable.swift` - SwiftUI 桥接参考

  **Acceptance Criteria**:
  - [ ] SwiftUI 中可使用 CAGridView
  - [ ] 生命周期管理正确
  - [ ] 事件协调正常

  **QA Scenarios**:
  ```
  Scenario: SwiftUI 桥接测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/CAGridViewRepresentableTests
    Expected Result: SwiftUI 中正确显示和使用
    Evidence: .sisyphus/evidence/task-21-representable.txt
  ```

  **Commit**: NO (groups with Wave 4)

- [ ] 22. PerformanceMode 切换逻辑

  **What to do**:
  - 定义 `PerformanceMode` 枚举（swiftUI, coreAnimation）
  - 实现性能模式切换逻辑
  - 在设置中添加模式选择
  - 提示用户重启应用

  **Must NOT do**:
  - 不要在运行时热切换（需要重启）
  - 不要丢失用户数据

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4
  - **Blocks**: Task 24, 29
  - **Blocked By**: Tasks 9, 21

  **References**:
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/PerformanceMode.swift` - 性能模式参考

  **Acceptance Criteria**:
  - [ ] 模式切换保存正确
  - [ ] 重启后生效
  - [ ] 单元测试覆盖

  **QA Scenarios**:
  ```
  Scenario: 性能模式测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/PerformanceModeTests
    Expected Result: 模式切换正确保存和加载
    Evidence: .sisyphus/evidence/task-22-perfmode.txt
  ```

  **Commit**: YES
  - Message: `feat(rendering): add CA grid view`
  - Files: `CAGridView.swift`, `CAGridView+Layout.swift`, `CAGridView+Input.swift`, `CAGridViewRepresentable.swift`, `PerformanceMode.swift`

### Wave 5: UI Components (SwiftUI 视图)

- [ ] 23. LauncherApp 主应用入口

  **What to do**:
  - 重构 `Launcher4App.swift` 主应用结构
  - 配置依赖注入容器
  - 设置主窗口样式（无边框、透明背景）
  - 初始化所有服务

  **Must NOT do**:
  - 不要在 App 中存储业务状态
  - 不要阻塞启动流程

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Tasks 24-30
  - **Blocked By**: Tasks 5, 6, 11, 12

  **References**:
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/LaunchpadApp.swift` - 主应用结构参考

  **Acceptance Criteria**:
  - [ ] 应用启动正常
  - [ ] 依赖注入配置完成
  - [ ] 窗口样式正确

  **QA Scenarios**:
  ```
  Scenario: 应用启动测试
    Tool: Bash
    Steps:
      1. xcodebuild build 验证应用编译
      2. 运行应用检查启动日志
    Expected Result: 应用启动成功，无崩溃
    Evidence: .sisyphus/evidence/task-23-app.txt
  ```

  **Commit**: NO (groups with Wave 5)

- [ ] 24. LaunchpadView 主界面

  **What to do**:
  - 实现 `LaunchpadView` SwiftUI 视图
  - 布局：顶部搜索栏、中部网格、底部页面指示器
  - 支持双渲染模式切换
  - 处理背景模糊效果
  - 集成所有子视图

  **Must NOT do**:
  - 不要在视图中执行业务逻辑
  - 不要硬编码尺寸

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `frontend-ui-ux`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Task 40
  - **Blocked By**: Tasks 13, 15, 21, 22, 23

  **References**:
  - `.specs/requirements.md:21-36` - 应用网格展示需求 R1
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/LaunchpadView.swift` - 主视图参考

  **Acceptance Criteria**:
  - [ ] 布局正确显示
  - [ ] 支持双渲染模式
  - [ ] 背景模糊效果正常
  - [ ] 响应式设计

  **QA Scenarios**:
  ```
  Scenario: 主界面 UI 测试
    Tool: Playwright
    Steps:
      1. 启动应用
      2. 验证搜索栏、网格、页面指示器存在
      3. 截图验证布局
    Expected Result: UI 元素正确显示
    Evidence: .sisyphus/evidence/task-24-launchpad.png
  ```

  **Commit**: NO (groups with Wave 5)

- [ ] 25. ApplicationIconView 图标组件

  **What to do**:
  - 实现 `ApplicationIconView` SwiftUI 视图
  - 显示应用图标和名称标签
  - 支持运行状态指示器（小圆点）
  - 实现悬停效果和工具提示
  - 处理图标大小调整

  **Must NOT do**:
  - 不要阻塞图标加载
  - 不要硬编码图标尺寸

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 10, 13

  **References**:
  - `.specs/requirements.md:21-36` - 应用网格展示需求 R1
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/LaunchpadItemButton.swift` - 图标组件参考

  **Acceptance Criteria**:
  - [ ] 图标正确显示
  - [ ] 运行状态指示器正常
  - [ ] 悬停效果正常

  **QA Scenarios**:
  ```
  Scenario: 图标组件测试
    Tool: Playwright
    Steps:
      1. 验证图标显示
      2. 验证悬停效果
    Expected Result: 图标和状态正确显示
    Evidence: .sisyphus/evidence/task-25-icon.png
  ```

  **Commit**: NO (groups with Wave 5)

- [ ] 26. FolderView 文件夹视图

  **What to do**:
  - 实现 `FolderView` SwiftUI 视图
  - 显示文件夹图标和名称
  - 实现文件夹展开/收起（弹出视图）
  - 支持文件夹拖拽管理
  - 处理文件夹颜色主题

  **Must NOT do**:
  - 不要在文件夹外部显示展开视图
  - 不要阻塞文件夹图标生成

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 8, 13

  **References**:
  - `.specs/requirements.md:67-83` - 文件夹管理需求 R4
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/FolderView.swift` - 文件夹视图参考

  **Acceptance Criteria**:
  - [ ] 文件夹图标正确显示
  - [ ] 展开/收起动画流畅
  - [ ] 拖拽管理正常

  **QA Scenarios**:
  ```
  Scenario: 文件夹视图测试
    Tool: Playwright
    Steps:
      1. 点击文件夹验证展开
      2. 点击外部验证收起
    Expected Result: 展开/收起正常
    Evidence: .sisyphus/evidence/task-26-folder.png
  ```

  **Commit**: NO (groups with Wave 5)

- [ ] 27. SearchView 搜索界面

  **What to do**:
  - 实现 `SearchView` SwiftUI 视图
  - 显示实时搜索结果列表（居中）
  - 支持搜索框焦点管理
  - 处理空状态和错误提示
  - 键盘快捷键支持（ESC 清空）

  **Must NOT do**:
  - 不要在搜索时阻塞 UI
  - 不要显示隐藏的应用

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 14

  **References**:
  - `.specs/requirements.md:52-66` - 搜索需求 R3

  **Acceptance Criteria**:
  - [ ] 搜索结果实时更新
  - [ ] 空状态提示正确
  - [ ] ESC 键清空搜索

  **QA Scenarios**:
  ```
  Scenario: 搜索界面测试
    Tool: Playwright
    Steps:
      1. 输入搜索关键词
      2. 验证结果过滤
      3. 按 ESC 验证清空
    Expected Result: 搜索过滤正确
    Evidence: .sisyphus/evidence/task-27-search.png
  ```

  **Commit**: NO (groups with Wave 5)

- [ ] 28. PageIndicatorView 页面指示器

  **What to do**:
  - 实现 `PageIndicatorView` SwiftUI 视图
  - 显示页面圆点指示器
  - 支持点击跳转页面
  - 当前页面高亮显示

  **Must NOT do**:
  - 不要在单页时显示指示器
  - 不要阻塞页面切换动画

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 15

  **References**:
  - `.specs/requirements.md:84-100` - 多页面导航需求 R5

  **Acceptance Criteria**:
  - [ ] 圆点数量正确
  - [ ] 点击跳转正常
  - [ ] 当前页高亮

  **QA Scenarios**:
  ```
  Scenario: 页面指示器测试
    Tool: Playwright
    Steps:
      1. 验证圆点数量与页面数匹配
      2. 点击圆点验证页面跳转
    Expected Result: 跳转正常
    Evidence: .sisyphus/evidence/task-28-indicator.png
  ```

  **Commit**: NO (groups with Wave 5)

- [ ] 29. SettingsView 设置界面

  **What to do**:
  - 实现 `SettingsView` SwiftUI 视图
  - 图标大小调整（小、中、大）
  - 网格尺寸调整（行/列）
  - 快捷键配置
  - 外观模式选择
  - 重置功能

  **Must NOT do**:
  - 不要实时应用所有设置（某些需要重启）
  - 不要丢失用户设置

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `frontend-ui-ux`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Task 40
  - **Blocked By**: Tasks 9, 22

  **References**:
  - `.specs/requirements.md:206-217` - 个性化设置需求 R13
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/SettingsView.swift` - 设置界面参考

  **Acceptance Criteria**:
  - [ ] 所有设置项可用
  - [ ] 设置立即生效或提示重启
  - [ ] 重置功能正常

  **QA Scenarios**:
  ```
  Scenario: 设置界面测试
    Tool: Playwright
    Steps:
      1. 打开设置界面
      2. 修改各项设置
      3. 验证设置保存
    Expected Result: 设置保存正确
    Evidence: .sisyphus/evidence/task-29-settings.png
  ```

  **Commit**: NO (groups with Wave 5)

- [ ] 30. EditModeOverlay 编辑模式覆盖层

  **What to do**:
  - 实现 `EditModeOverlay` SwiftUI 视图
  - 显示图标抖动动画
  - 显示删除按钮（×）
  - 处理拖拽重新排列
  - 支持退出编辑模式（ESC/点击背景）

  **Must NOT do**:
  - 不要为系统应用显示删除按钮
  - 不要在动画中响应拖拽

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 13

  **References**:
  - `.specs/requirements.md:101-117` - 编辑模式需求 R6

  **Acceptance Criteria**:
  - [ ] 抖动动画正常
  - [ ] 删除按钮正确显示
  - [ ] 拖拽重排正常

  **QA Scenarios**:
  ```
  Scenario: 编辑模式测试
    Tool: Playwright
    Steps:
      1. 长按图标进入编辑模式
      2. 验证抖动动画和删除按钮
      3. 拖拽图标验证重排
    Expected Result: 编辑模式功能正常
    Evidence: .sisyphus/evidence/task-30-editmode.png
  ```

  **Commit**: YES
  - Message: `feat(ui): add SwiftUI views`
  - Files: `Launcher4App.swift`, `LaunchpadView.swift`, `ApplicationIconView.swift`, `FolderView.swift`, `SearchView.swift`, `PageIndicatorView.swift`, `SettingsView.swift`, `EditModeOverlay.swift`

### Wave 6: System Integration (系统集成)

- [ ] 31. GestureManager 触控板手势

  **What to do**:
  - 实现 `GestureManager` actor
  - 识别触控板手势（捏合打开、滑动切换页面）
  - 控制手势误识别率 < 5%
  - 集成系统手势设置

  **Must NOT do**:
  - 不要与系统手势冲突
  - 不要在高负载时启用手势

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 9, 23

  **References**:
  - `.specs/design.md:259-285` - GestureManager 设计
  - `.specs/requirements.md:166-178` - 触控板手势需求 R10

  **Acceptance Criteria**:
  - [ ] 手势识别正确
  - [ ] 误识别率 < 5%
  - [ ] 响应时间 < 0.3s

  **QA Scenarios**:
  ```
  Scenario: 手势测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/GestureManagerTests
    Expected Result: 手势识别正确
    Evidence: .sisyphus/evidence/task-31-gesture.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [ ] 32. AnimationManager 动画管理

  **What to do**:
  - 实现 `AnimationManager` 类（@MainActor）
  - 创建应用启动动画（缩放）
  - 实现页面切换动画（滑动）
  - 支持编辑模式动画（抖动）
  - 处理减少动画效果选项

  **Must NOT do**:
  - 不要在动画中阻塞交互
  - 不要忽略减少动画设置

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6
  - **Blocks**: Tasks 24, 30
  - **Blocked By**: Task 23

  **References**:
  - `.specs/design.md:329-352` - AnimationManager 设计
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/Animations.swift` - 动画参考

  **Acceptance Criteria**:
  - [ ] 所有动画流畅
  - [ ] 支持减少动画
  - [ ] 动画时间符合需求

  **QA Scenarios**:
  ```
  Scenario: 动画测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/AnimationManagerTests
    Expected Result: 动画配置正确
    Evidence: .sisyphus/evidence/task-32-animation.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [ ] 33. WindowController 窗口控制

  **What to do**:
  - 实现 `WindowController` 类
  - 创建无边框窗口
  - 管理窗口位置（居中/全屏）
  - 处理窗口层级
  - 实现点击外部关闭

  **Must NOT do**:
  - 不要让窗口始终在最前（可选）
  - 不要在动画中改变窗口位置

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6
  - **Blocks**: Task 24
  - **Blocked By**: Tasks 11, 23

  **References**:
  - `.specs/requirements.md:119-133` - Launcher 显示与隐藏需求 R7

  **Acceptance Criteria**:
  - [ ] 窗口样式正确
  - [ ] 位置管理正常
  - [ ] 点击外部关闭

  **QA Scenarios**:
  ```
  Scenario: 窗口控制测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/WindowControllerTests
    Expected Result: 窗口行为正确
    Evidence: .sisyphus/evidence/task-33-window.txt
  ```

  **Commit**: NO (groups with Wave 6)

- [ ] 34. LocalizationManager 国际化

  **What to do**:
  - 实现 `LocalizationManager` 类
  - 管理多语言资源加载
  - 支持动态语言切换
  - 创建中英文本地化文件

  **Must NOT do**:
  - 不要硬编码 UI 字符串
  - 不要忽略系统语言设置

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6
  - **Blocks**: Tasks 24, 29
  - **Blocked By**: Task 1

  **References**:
  - `.specs/design.md:929-1033` - 国际化设计
  - `/Users/Sam/git/Github/LaunchNext2/LaunchNext/Localization.swift` - 本地化参考

  **Acceptance Criteria**:
  - [ ] 中英文切换正常
  - [ ] 所有 UI 字符串本地化
  - [ ] 跟随系统语言

  **QA Scenarios**:
  ```
  Scenario: 国际化测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/LocalizationManagerTests
    Expected Result: 语言切换正确
    Evidence: .sisyphus/evidence/task-34-i18n.txt
  ```

  **Commit**: YES
  - Message: `feat(integration): add system integration`
  - Files: `GestureManager.swift`, `AnimationManager.swift`, `WindowController.swift`, `LocalizationManager.swift`, `en.lproj/`, `zh-Hans.lproj/`

### Wave 7: Tests & Polish (测试与优化)

- [ ] 35. 单元测试补充

  **What to do**:
  - 补充所有核心模块的单元测试
  - 覆盖边界情况
  - 覆盖错误处理路径
  - 确保测试覆盖率 ≥ 80%

  **Must NOT do**:
  - 不要跳过失败的测试
  - 不要测试私有方法（通过公共接口测试）

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7
  - **Blocks**: Task 40
  - **Blocked By**: Tasks 1-34

  **References**:
  - `.specs/tasks.md` - 测试任务参考

  **Acceptance Criteria**:
  - [ ] 所有测试通过
  - [ ] 覆盖率 ≥ 80%

  **QA Scenarios**:
  ```
  Scenario: 测试覆盖率验证
    Tool: Bash
    Steps:
      1. xcodebuild test -enableCodeCoverage YES
      2. 检查覆盖率报告
    Expected Result: 覆盖率 ≥ 80%
    Evidence: .sisyphus/evidence/task-35-coverage.txt
  ```

  **Commit**: YES
  - Message: `test: add comprehensive unit tests`
  - Files: `Launcher4Tests/`

- [ ] 36. 性能优化与内存管理

  **What to do**:
  - 优化应用启动时间（目标 < 500ms）
  - 优化搜索响应时间（目标 < 100ms）
  - 优化内存使用（目标 < 150MB）
  - 确保动画帧率 ≥ 60fps
  - 实现内存警告处理

  **Must NOT do**:
  - 不要牺牲功能换取性能
  - 不要在主线程执行繁重操作

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7
  - **Blocks**: Task 41
  - **Blocked By**: Tasks 1-34

  **References**:
  - `.specs/design.md:1221-1553` - 性能优化设计
  - `.specs/requirements.md:317-329` - 性能需求 NFR-001

  **Acceptance Criteria**:
  - [ ] 冷启动 < 500ms
  - [ ] 搜索响应 < 100ms
  - [ ] 内存使用 < 150MB
  - [ ] 动画 ≥ 60fps

  **QA Scenarios**:
  ```
  Scenario: 性能基准测试
    Tool: Bash
    Steps:
      1. 运行性能测试脚本
      2. 记录各项指标
    Expected Result: 所有指标达标
    Evidence: .sisyphus/evidence/task-36-perf.txt
  ```

  **Commit**: NO (groups with Wave 7)

- [ ] 37. 可访问性支持完善

  **What to do**:
  - 为所有 UI 元素添加 VoiceOver 标签
  - 确保键盘导航完整
  - 支持高对比度模式
  - 支持减少动画效果

  **Must NOT do**:
  - 不要忽略辅助功能设置
  - 不要使用仅视觉的反馈

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7
  - **Blocks**: Task F4
  - **Blocked By**: Tasks 17, 24

  **References**:
  - `.specs/requirements.md:194-205` - 可访问性需求 R12
  - `.specs/requirements.md:369-374` - 可访问性 NFR-006

  **Acceptance Criteria**:
  - [ ] VoiceOver 正常朗读
  - [ ] 键盘导航完整
  - [ ] 高对比度支持

  **QA Scenarios**:
  ```
  Scenario: 可访问性测试
    Tool: Bash
    Steps:
      1. 启用 VoiceOver 测试
      2. 键盘导航测试
    Expected Result: 辅助功能正常
    Evidence: .sisyphus/evidence/task-37-a11y.txt
  ```

  **Commit**: NO (groups with Wave 7)

- [ ] 38. 边界情况处理

  **What to do**:
  - 处理空状态（无应用）
  - 处理图标加载失败
  - 处理应用启动失败
  - 处理数据损坏恢复

  **Must NOT do**:
  - 不要在边界情况下崩溃
  - 不要显示空白界面

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 7
  - **Blocks**: Task 40
  - **Blocked By**: Tasks 1-34

  **References**:
  - `.specs/requirements.md:304-315` - 空状态与边界处理需求 R21

  **Acceptance Criteria**:
  - [ ] 空状态显示提示
  - [ ] 错误处理优雅
  - [ ] 不崩溃

  **QA Scenarios**:
  ```
  Scenario: 边界情况测试
    Tool: Bash
    Steps:
      1. 测试无应用状态
      2. 测试图标加载失败
      3. 测试应用启动失败
    Expected Result: 优雅处理，无崩溃
    Evidence: .sisyphus/evidence/task-38-edge.txt
  ```

  **Commit**: YES
  - Message: `chore: add performance optimization and edge case handling`
  - Files: various files

### Wave 8: Final Integration (最终集成)

- [ ] 39. 组件连接与依赖注入配置

  **What to do**:
  - 在 DIContainer 中注册所有组件
  - 配置组件间依赖关系
  - 设置应用生命周期管理
  - 集成所有系统服务

  **Must NOT do**:
  - 不要循环依赖
  - 不要忘记释放资源

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 8
  - **Blocks**: Task 40
  - **Blocked By**: Tasks 1-38

  **References**:
  - `.specs/design.md:507-569` - 依赖注入配置

  **Acceptance Criteria**:
  - [ ] 所有组件正确注入
  - [ ] 生命周期管理正确
  - [ ] 无循环依赖

  **QA Scenarios**:
  ```
  Scenario: 依赖注入测试
    Tool: Bash
    Steps:
      1. xcodebuild test -only-testing:Launcher4Tests/DIContainerTests
    Expected Result: 所有依赖正确解析
    Evidence: .sisyphus/evidence/task-39-di.txt
  ```

  **Commit**: NO (groups with Wave 8)

- [ ] 40. 端到端测试

  **What to do**:
  - 测试完整用户流程
  - 测试应用启动流程
  - 测试搜索功能
  - 测试文件夹创建和管理
  - 测试设置更改

  **Must NOT do**:
  - 不要跳过 E2E 测试
  - 不要依赖外部状态

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 8
  - **Blocks**: Task 41
  - **Blocked By**: Tasks 1-39

  **References**:
  - `.specs/requirements.md` - 所有功能需求

  **Acceptance Criteria**:
  - [ ] 所有用户流程正常
  - [ ] 无阻塞问题

  **QA Scenarios**:
  ```
  Scenario: E2E 测试
    Tool: Playwright
    Steps:
      1. 启动应用
      2. 搜索应用
      3. 创建文件夹
      4. 修改设置
    Expected Result: 所有流程正常
    Evidence: .sisyphus/evidence/task-40-e2e.png
  ```

  **Commit**: NO (groups with Wave 8)

- [ ] 41. 性能基准验证

  **What to do**:
  - 验证冷启动时间 < 500ms
  - 验证搜索响应 < 100ms
  - 验证内存使用 < 150MB
  - 验证动画帧率 ≥ 60fps

  **Must NOT do**:
  - 不要跳过性能验证
  - 不要伪造性能数据

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 8
  - **Blocks**: Task F1-F4
  - **Blocked By**: Tasks 36, 40

  **References**:
  - `.specs/requirements.md:317-329` - 性能需求 NFR-001

  **Acceptance Criteria**:
  - [ ] 所有性能指标达标

  **QA Scenarios**:
  ```
  Scenario: 性能验证
    Tool: Bash
    Steps:
      1. 运行性能基准测试
      2. 记录并对比指标
    Expected Result: 所有指标达标
    Evidence: .sisyphus/evidence/task-41-benchmark.txt
  ```

  **Commit**: NO (groups with Wave 8)

- [ ] 42. 文档与代码注释

  **What to do**:
  - 为所有公开 API 添加文档注释
  - 更新 README.md
  - 添加使用说明
  - 添加架构说明

  **Must NOT do**:
  - 不要添加过时注释
  - 不要遗漏重要 API

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: 无特殊技能需求

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 8
  - **Blocks**: None
  - **Blocked By**: Tasks 1-40

  **References**:
  - `/Users/Sam/git/Github/LaunchNext2/README.md` - README 参考

  **Acceptance Criteria**:
  - [ ] 所有公开 API 有文档
  - [ ] README 完整

  **QA Scenarios**:
  ```
  Scenario: 文档验证
    Tool: Bash
    Steps:
      1. 检查文档覆盖率
      2. 验证 README 完整性
    Expected Result: 文档完整
    Evidence: .sisyphus/evidence/task-42-docs.txt
  ```

  **Commit**: YES
  - Message: `docs: add documentation and code comments`
  - Files: various files, README.md

---

## Final Verification Wave

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Verify all "Must Have" features implemented. Check evidence files exist. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `swift build` + tests. Review for: force unwraps, empty catches, unused imports, AI slop patterns.
  Output: `Build [PASS/FAIL] | Tests [N pass/N fail] | Quality [N/N] | VERDICT`

- [ ] F3. **Performance Verification** — `unspecified-high`
  Measure cold start, search response, memory usage. Verify 60fps animations.
  Output: `Start [<500ms] | Search [<100ms] | Memory [<150MB] | FPS [≥60] | VERDICT`

- [ ] F4. **Accessibility Check** — `unspecified-high`
  Test VoiceOver labels, keyboard navigation, focus indicators.
  Output: `VoiceOver [N/N] | Keyboard [N/N] | Focus [N/N] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `feat(core): add project foundation` — all Wave 1 files
- **Wave 2**: `feat(services): add service layer actors` — all Wave 2 files
- **Wave 3**: `feat(viewmodels): add view models` — all Wave 3 files
- **Wave 4**: `feat(rendering): add CA grid view` — all Wave 4 files
- **Wave 5**: `feat(ui): add SwiftUI views` — all Wave 5 files
- **Wave 6**: `feat(integration): add system integration` — all Wave 6 files
- **Wave 7**: `test: add comprehensive tests` — all Wave 7 files
- **Wave 8**: `chore: final integration and polish` — all Wave 8 files

---

## Success Criteria

### Verification Commands
```bash
# 构建验证
xcodebuild -project Launcher4.xcodeproj -scheme Launcher4 -configuration Debug build

# 测试验证
xcodebuild test -project Launcher4.xcodeproj -scheme Launcher4 -destination 'platform=macOS'

# 性能验证
# 冷启动时间 < 500ms
# 搜索响应 < 100ms
# 内存占用 < 150MB
# 动画帧率 ≥ 60fps
```

### Final Checklist
- [ ] 所有 Must Have 功能实现
- [ ] 所有 Must NOT Have 功能未实现
- [ ] 所有单元测试通过
- [ ] 性能指标达标
- [ ] 可访问性支持完整
- [ ] 中英文国际化支持
