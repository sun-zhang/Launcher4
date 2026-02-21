import SwiftUI

struct LaunchpadView: View {
    @StateObject private var viewModel: ApplicationGridViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var pageNavigator: PageNavigator
    
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var performanceMode: PerformanceMode = .swiftUI
    
    private let gridSize = GridSize.default
    
    init() {
        let appScanner = DIContainer.shared.resolve(ApplicationScannerProtocol.self)
        let folderManager = DIContainer.shared.resolve(FolderManagerProtocol.self)
        let settingsManager = DIContainer.shared.resolve(SettingsManagerProtocol.self)
        let eventBus = DIContainer.shared.resolve(EventBusProtocol.self)
        
        _viewModel = StateObject(wrappedValue: ApplicationGridViewModel(
            applicationScanner: appScanner as! ApplicationScanner,
            folderManager: folderManager as! FolderManager,
            settingsManager: settingsManager as! SettingsManager,
            eventBus: eventBus as! EventBus
        ))
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(
            applicationScanner: appScanner as! ApplicationScanner,
            eventBus: eventBus as! EventBus
        ))
        _pageNavigator = StateObject(wrappedValue: PageNavigator(
            gridSize: .default,
            eventBus: eventBus as! EventBus
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minIconSize: CGFloat = 48
            let maxIconSize: CGFloat = 128
            let minSpacing: CGFloat = 16
            let maxSpacing: CGFloat = 64
            let columns = 7 // 固定列数，可根据需要调整
            // 计算最大可用宽度
            let totalMinWidth = CGFloat(columns) * minIconSize + CGFloat(columns + 1) * minSpacing
            let totalMaxWidth = CGFloat(columns) * maxIconSize + CGFloat(columns + 1) * maxSpacing
            // 计算当前可用宽度下的 iconSize 和 spacing
            let availableWidth = width
            let t = (availableWidth - totalMinWidth) / (totalMaxWidth - totalMinWidth)
            let iconSize = availableWidth <= totalMinWidth ? minIconSize : (availableWidth >= totalMaxWidth ? maxIconSize : minIconSize + t * (maxIconSize - minIconSize))
            let spacing = availableWidth <= totalMinWidth ? minSpacing : (availableWidth >= totalMaxWidth ? maxSpacing : minSpacing + t * (maxSpacing - minSpacing))
            ZStack {
                backgroundBlur
                mainContent(columns: columns, iconSize: iconSize, spacing: spacing)
            }
            .onAppear {
                Task {
                    await viewModel.loadApplications()
                }
            }
        }
    }
    
    private var backgroundBlur: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .background(.ultraThinMaterial)
    }
    
    private func mainContent(columns: Int, iconSize: CGFloat, spacing: CGFloat) -> some View {
        VStack(spacing: 0) {
            searchSection
            Spacer()
            gridSection(columns: columns, iconSize: iconSize, spacing: spacing)
            Spacer()
            pageIndicatorSection
        }
        .padding()
    }
    
    private var searchSection: some View {
        SearchView(
            searchText: $searchText,
            searchResults: searchViewModel.searchResults,
            onSelectApplication: { app in
                launchApplication(app)
            },
            onClear: {
                isSearching = false
            }
        )
        .frame(maxWidth: 400)
        .onChange(of: searchText) { _, newValue in
            Task {
                searchViewModel.search(newValue)
            }
            isSearching = !newValue.isEmpty
        }
    }
    
    @ViewBuilder
    private func gridSection(columns: Int, iconSize: CGFloat, spacing: CGFloat) -> some View {
        if isSearching {
            searchResultsGrid(columns: columns, iconSize: iconSize, spacing: spacing)
        } else {
            applicationGrid(columns: columns, iconSize: iconSize, spacing: spacing)
        }
    }
    
    private func searchResultsGrid(columns: Int, iconSize: CGFloat, spacing: CGFloat) -> some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(iconSize), spacing: spacing), count: columns), spacing: spacing) {
                ForEach(searchViewModel.searchResults) { app in
                    ApplicationIconView(
                        application: app,
                        iconSize: iconSize,
                        isRunning: false,
                        isEditing: false
                    )
                    .onTapGesture {
                        launchApplication(app)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func applicationGrid(columns: Int, iconSize: CGFloat, spacing: CGFloat) -> some View {
        switch performanceMode {
        case .swiftUI:
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(iconSize), spacing: spacing), count: columns), spacing: spacing) {
                    ForEach(viewModel.folders) { folder in
                        FolderView(
                            folder: folder,
                            iconSize: iconSize,
                            isOpen: false,
                            onToggle: {},
                            onApplicationSelected: { appId in }
                        )
                    }
                    ForEach(viewModel.applications) { app in
                        ApplicationIconView(
                            application: app,
                            iconSize: iconSize,
                            isRunning: false,
                            isEditing: viewModel.isEditing
                        )
                        .editMode(isEditing: viewModel.isEditing) {
                            Task {
                                try? await viewModel.deleteApplication(app)
                            }
                        }
                        .onTapGesture {
                            if !viewModel.isEditing {
                                launchApplication(app)
                            }
                        }
                    }
                }
                .padding()
            }
        case .coreAnimation:
            caGridRepresentable
        }
    }
    
    private var caGridRepresentable: some View {
        CAGridViewRepresentable(
            applications: viewModel.applications,
            folders: viewModel.folders,
            gridSize: gridSize,
            currentPage: pageNavigator.currentPage,
            iconSize: 64
        )
        .onApplicationClick { app in
            launchApplication(app)
        }
    }
    
    @ViewBuilder
    private var pageIndicatorSection: some View {
        if !isSearching && pageNavigator.totalPages > 1 {
            PageIndicatorView(
                totalPages: pageNavigator.totalPages,
                currentPage: pageNavigator.currentPage,
                onPageSelected: { page in
                    pageNavigator.goToPage(page)
                }
            )
        }
    }
    
    private func launchApplication(_ app: ApplicationInfo) {
        Task {
            await viewModel.launchApplication(app)
        }
    }
}
