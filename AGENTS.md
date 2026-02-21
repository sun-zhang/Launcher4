# Launcher4 项目开发指南

## 项目概述

macOS Launcher 是一个类似 Launchpad 的应用程序启动器，使用 SwiftUI 开发，目标平台 macOS 26 Tahoe。

## 构建命令

```bash
# 构建项目
xcodebuild -project Launcher4.xcodeproj -scheme Launcher4 -configuration Debug build

# 构建发布版本
xcodebuild -project Launcher4.xcodeproj -scheme Launcher4 -configuration Release build

# 清理构建
xcodebuild -project Launcher4.xcodeproj -scheme Launcher4 clean

# 运行所有测试
xcodebuild test -project Launcher4.xcodeproj -scheme Launcher4 -destination 'platform=macOS'

# 运行单个测试类
xcodebuild test -project Launcher4.xcodeproj -scheme Launcher4 -destination 'platform=macOS' -only-testing:Launcher4Tests/SpecificTestClass

# 运行单个测试方法
xcodebuild test -project Launcher4.xcodeproj -scheme Launcher4 -destination 'platform=macOS' -only-testing:Launcher4Tests/SpecificTestClass/testMethodName
```

## 架构原则

- **MVVM 模式**: View-ViewModel-Model 分层，分离 UI 和业务逻辑
- **单一职责**: 每个组件只负责一个明确功能
- **依赖注入**: 通过 DIContainer 管理组件依赖
- **协议优先**: 使用 Protocol 定义接口，便于测试和替换

## 并发安全

```swift
// Actor 用于后台服务
actor ApplicationScanner: ApplicationScannerProtocol {
    func scanApplications() async -> [ApplicationInfo]
}

// @MainActor 用于 UI 相关的 ViewModel
@MainActor
class ApplicationGridViewModel: ObservableObject {
    @Published var applications: [ApplicationInfo]
}
```

## 数据模型

所有数据模型必须实现 `Sendable` 协议：

```swift
struct ApplicationInfo: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
}
```

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类 | PascalCase | `ApplicationScanner` |
| 协议 | PascalCase + Protocol 后缀 | `ApplicationScannerProtocol` |
| Actor | PascalCase | `FolderManager` |
| 结构体 | PascalCase | `ApplicationInfo` |
| 枚举 | PascalCase | `AppearanceMode` |
| 函数/方法 | camelCase | `scanApplications()` |
| 变量/属性 | camelCase | `applicationList` |
| 常量 | camelCase 或 PascalCase | `maxRetryCount` |

## 导入顺序

```swift
// 1. 系统框架
import SwiftUI
import Combine
import Foundation
// 2. 第三方库（如有）
// 3. 项目内部模块
```

## SwiftUI View 结构

```swift
struct ApplicationGridView: View {
    // 1. 环境对象
    @EnvironmentObject var viewModel: ApplicationGridViewModel
    // 2. 状态属性
    @State private var isEditing = false
    // 3. 绑定属性
    @Binding var selectedApp: ApplicationInfo?
    // 4. 普通属性
    private let columns = 7
    
    var body: some View { /* ... */ }
}
```

## 错误处理

```swift
enum LauncherError: Error, Sendable {
    case applicationNotFound(String)
    case launchFailed(String)
}

do {
    try await launcher.launchApplication(appId)
} catch {
    logger.error("启动失败: \(error)")
}
```

## 注释规范

```swift
/// 扫描系统中的应用程序
/// - Returns: 应用程序信息数组
func scanApplications() async -> [ApplicationInfo] { }

// MARK: - Public Methods
// MARK: - Private Methods
// TODO: 实现缓存优化
// FIXME: 修复问题
```

## 文件组织

```
Launcher4/
├── Launcher4App.swift          # 应用入口
├── Models/                      # 数据模型 (Sendable)
├── ViewModels/                  # 视图模型 (@MainActor)
├── Views/                       # SwiftUI 视图
├── Services/                    # 业务服务 (Actor)
├── Protocols/                   # 协议定义
├── Utilities/                   # 工具类
└── Resources/                   # 资源文件
```

## 性能要求

- 冷启动时间 < 500ms
- 应用列表渲染 < 300ms
- 搜索响应 < 100ms
- 内存占用 < 150MB
- 动画帧率 60fps

## 重要约束

1. 最低支持 macOS 26.2
2. 遵循 Apple Human Interface Guidelines
3. 启用 App Sandbox
4. Swift 版本 5.0+
5. 禁止使用 `as Any`、`@ts-ignore` 等类型安全规避
6. 所有跨线程数据传递必须确保 Sendable 安全

## 可访问性与国际化

- 支持 VoiceOver、键盘导航、高对比度模式、减少动态效果
- 使用 `NSLocalizedString` 或 SwiftUI `Text` 自动本地化
- 支持中英文界面
