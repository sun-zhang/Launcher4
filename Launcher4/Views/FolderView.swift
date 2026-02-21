import SwiftUI

struct FolderView: View {
    let folder: FolderInfo
    let iconSize: CGFloat
    let isOpen: Bool
    let onToggle: (() -> Void)?
    let onApplicationSelected: ((String) -> Void)?
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            folderIcon
            nameLabel
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onToggle?() }
        .popover(isPresented: .constant(isOpen), arrowEdge: .bottom) {
            FolderPopoverContent(
                folder: folder,
                onApplicationSelected: onApplicationSelected
            )
        }
    }
    
    private var folderIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: iconSize, height: iconSize)
            Image(systemName: "folder.fill")
                .font(.system(size: iconSize * 0.5))
                .foregroundColor(.white)
        }
    }
    
    private var nameLabel: some View {
        Text(folder.name.currentLanguage)
            .font(.caption)
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: iconSize + 20)
    }
}

struct FolderPopoverContent: View {
    let folder: FolderInfo
    let onApplicationSelected: ((String) -> Void)?
    
    private let gridColumns = Array(repeating: GridItem(.fixed(64), spacing: 8), count: 4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(folder.name.currentLanguage)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(folder.applications, id: \.self) { appId in
                        FolderAppItem(applicationId: appId) {
                            onApplicationSelected?(appId)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 320, height: 280)
    }
}

struct FolderAppItem: View {
    let applicationId: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: applicationId) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appUrl.path))
                    .resizable()
                    .frame(width: 48, height: 48)
                Text(applicationId)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .onTapGesture { onTap() }
    }
}
