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
            let maxIconSize: CGFloat = 110
            let minSpacingX: CGFloat = 32
            let maxSpacingX: CGFloat = 64
            let minSpacingY: CGFloat = 24
            let maxSpacingY: CGFloat = 48
            let columns = 7 // 固定列数
            let rows = 5 // 固定行数
            let totalMinWidth = CGFloat(columns) * minIconSize + CGFloat(columns + 1) * minSpacingX
            let totalMaxWidth = CGFloat(columns) * maxIconSize + CGFloat(columns + 1) * maxSpacingX
            let totalMinHeight = CGFloat(rows) * minIconSize + CGFloat(rows + 1) * minSpacingY
            let totalMaxHeight = CGFloat(rows) * maxIconSize + CGFloat(rows + 1) * maxSpacingY
            let availableWidth = width
            let availableHeight = height
            let tX = (availableWidth - totalMinWidth) / (totalMaxWidth - totalMinWidth)
            let tY = (availableHeight - totalMinHeight) / (totalMaxHeight - totalMinHeight)
            let iconSize = min(
                availableWidth <= totalMinWidth ? minIconSize : (availableWidth >= totalMaxWidth ? maxIconSize : minIconSize + tX * (maxIconSize - minIconSize)),
                availableHeight <= totalMinHeight ? minIconSize : (availableHeight >= totalMaxHeight ? maxIconSize : minIconSize + tY * (maxIconSize - minIconSize))
            )
            let spacingX = availableWidth <= totalMinWidth ? minSpacingX : (availableWidth >= totalMaxWidth ? maxSpacingX : minSpacingX + tX * (maxSpacingX - minSpacingX))
            let spacingY = availableHeight <= totalMinHeight ? minSpacingY : (availableHeight >= totalMaxHeight ? maxSpacingY : minSpacingY + tY * (maxSpacingY - minSpacingY))
            ZStack {
                backgroundBlur
                mainContent(columns: columns, rows: rows, iconSize: iconSize, spacingX: spacingX, spacingY: spacingY)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                NSApplication.shared.hide(nil)
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
    
    private func mainContent(columns: Int, rows: Int, iconSize: CGFloat, spacingX: CGFloat, spacingY: CGFloat) -> some View {
        VStack(spacing: 0) {
            searchSection
            Spacer()
            gridSection(columns: columns, rows: rows, iconSize: iconSize, spacingX: spacingX, spacingY: spacingY)
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
                Task {
                    await viewModel.loadApplications()
                }
            }
        )
        .frame(maxWidth: 400)
        .onChange(of: searchText) { _, newValue in
            Task {
                if newValue.isEmpty {
                    await viewModel.loadApplications()
                } else {
                    searchViewModel.search(newValue)
                }
            }
            isSearching = !newValue.isEmpty
        }
    }
    
    @ViewBuilder
    private func gridSection(columns: Int, rows: Int, iconSize: CGFloat, spacingX: CGFloat, spacingY: CGFloat) -> some View {
        if isSearching {
            searchResultsGrid(columns: columns, rows: rows, iconSize: iconSize, spacingX: spacingX, spacingY: spacingY)
        } else {
            applicationGrid(columns: columns, rows: rows, iconSize: iconSize, spacingX: spacingX, spacingY: spacingY)
        }
    }
    
    private func searchResultsGrid(columns: Int, rows: Int, iconSize: CGFloat, spacingX: CGFloat, spacingY: CGFloat) -> some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(iconSize), spacing: spacingX), count: columns), spacing: spacingY) {
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
    private func applicationGrid(columns: Int, rows: Int, iconSize: CGFloat, spacingX: CGFloat, spacingY: CGFloat) -> some View {
        switch performanceMode {
        case .swiftUI:
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(iconSize), spacing: spacingX), count: columns), spacing: spacingY) {
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
        // 立即异步隐藏窗口，保证主线程流畅
        DispatchQueue.main.async {
            NSApplication.shared.hide(nil)
        }
        Task.detached {
            await viewModel.launchApplication(app)
        }
    }
}
