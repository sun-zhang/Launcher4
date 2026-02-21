import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let settingsManager = DIContainer.shared.resolve(SettingsManagerProtocol.self)
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settingsManager: settingsManager))
    }
    
    var body: some View {
        TabView {
            GeneralSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            AppearanceSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("外观", systemImage: "paintbrush")
                }
            
            ShortcutSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
        }
        .frame(width: 450, height: 350)
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    let settingsManager: SettingsManagerProtocol
    
    @Published var iconSize: AppSettings.IconSize
    @Published var gridColumns: Int
    @Published var gridRows: Int
    @Published var appearance: AppSettings.AppearanceMode
    @Published var performanceMode: AppSettings.PerformanceMode
    @Published var shortcutKey: String
    
    init(settingsManager: SettingsManagerProtocol) {
        self.settingsManager = settingsManager
        self.iconSize = .medium
        self.gridColumns = 7
        self.gridRows = 5
        self.appearance = .auto
        self.performanceMode = .swiftUI
        self.shortcutKey = "F4"
    }
    
    func save() async {
        try? await settingsManager.setIconSize(iconSize)
        try? await settingsManager.setGridColumns(gridColumns)
        try? await settingsManager.setGridRows(gridRows)
        try? await settingsManager.setAppearanceMode(appearance)
        try? await settingsManager.setPerformanceMode(performanceMode)
    }
    
    func reset() async {
        try? await settingsManager.resetToDefaults()
        iconSize = .medium
        gridColumns = 7
        gridRows = 5
        appearance = .auto
        performanceMode = .swiftUI
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("性能模式") {
                Picker("渲染模式", selection: $viewModel.performanceMode) {
                    Text("SwiftUI").tag(AppSettings.PerformanceMode.swiftUI)
                    Text("Core Animation").tag(AppSettings.PerformanceMode.coreAnimation)
                }
                Text("更改后需要重启应用生效")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("重置所有设置") {
                    Task {
                        await viewModel.reset()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AppearanceSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("图标大小") {
                Picker("大小", selection: $viewModel.iconSize) {
                    Text("小").tag(AppSettings.IconSize.small)
                    Text("中").tag(AppSettings.IconSize.medium)
                    Text("大").tag(AppSettings.IconSize.large)
                }
            }
            
            Section("网格大小") {
                Stepper("列数: \(viewModel.gridColumns)", value: $viewModel.gridColumns, in: 4...10)
                Stepper("行数: \(viewModel.gridRows)", value: $viewModel.gridRows, in: 4...8)
            }
            
            Section("外观") {
                Picker("外观模式", selection: $viewModel.appearance) {
                    Text("自动").tag(AppSettings.AppearanceMode.auto)
                    Text("浅色").tag(AppSettings.AppearanceMode.light)
                    Text("深色").tag(AppSettings.AppearanceMode.dark)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("全局快捷键") {
                HStack {
                    Text("显示/隐藏")
                    Spacer()
                    Text(viewModel.shortcutKey)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                Text("点击更改快捷键（功能待实现）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
