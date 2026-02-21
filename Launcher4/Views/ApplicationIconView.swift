import SwiftUI

struct ApplicationIconView: View {
    let application: ApplicationInfo
    let iconSize: CGFloat
    let isRunning: Bool
    let isEditing: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                iconImage
                if isRunning {
                    runningIndicator
                }
            }
            nameLabel
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .help(application.displayName)
    }
    
    private var iconImage: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: application.bundleURL.path))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
    }
    
    private var runningIndicator: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 8, height: 8)
            .offset(x: 2, y: -2)
    }
    
    private var nameLabel: some View {
        Text(application.displayName)
            .font(.caption)
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: iconSize + 20)
    }
}
