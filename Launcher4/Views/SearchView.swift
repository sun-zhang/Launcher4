import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    let searchResults: [ApplicationInfo]
    let onSelectApplication: ((ApplicationInfo) -> Void)?
    let onClear: (() -> Void)?
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            searchField
            if searchText.isEmpty {
                emptyStateView
            } else if searchResults.isEmpty {
                noResultsView
            } else {
                resultsList
            }
        }
        .padding()
        .onAppear { isSearchFocused = true }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("搜索应用...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit {
                    if let first = searchResults.first {
                        onSelectApplication?(first)
                    }
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var emptyStateView: some View {
        Text("输入关键词搜索应用")
            .foregroundColor(.gray)
    }
    
    private var noResultsView: some View {
        Text("未找到匹配的应用")
            .foregroundColor(.gray)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(searchResults) { app in
                    SearchResultRow(application: app) {
                        onSelectApplication?(app)
                    }
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let application: ApplicationInfo
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: application.bundleURL.path))
                .resizable()
                .frame(width: 32, height: 32)
            Text(application.displayName)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
        .onTapGesture { onSelect() }
    }
}
