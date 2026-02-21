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
        ZStack {
            backgroundBlur
            mainContent
        }
        .onAppear {
            Task {
                await viewModel.loadApplications()
            }
        }
    }
    
    private var backgroundBlur: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .background(.ultraThinMaterial)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            searchSection
            Spacer()
            gridSection
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
    private var gridSection: some View {
        if isSearching {
            searchResultsGrid
        } else {
            applicationGrid
        }
    }
    
    private var searchResultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(80), spacing: 16), count: 7), spacing: 16) {
                ForEach(searchViewModel.searchResults) { app in
                    ApplicationIconView(
                        application: app,
                        iconSize: 64,
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
    private var applicationGrid: some View {
        switch performanceMode {
        case .swiftUI:
            swiftUIGrid
        case .coreAnimation:
            caGridRepresentable
        }
    }
    
    private var swiftUIGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(80), spacing: 16), count: gridSize.columns), spacing: 16) {
                ForEach(viewModel.folders) { folder in
                    FolderView(
                        folder: folder,
                        iconSize: 64,
                        isOpen: false,
                        onToggle: {},
                        onApplicationSelected: { appId in
                        }
                    )
                }
                ForEach(viewModel.applications) { app in
                    ApplicationIconView(
                        application: app,
                        iconSize: 64,
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
