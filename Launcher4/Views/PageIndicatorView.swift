import SwiftUI

struct PageIndicatorView: View {
    let totalPages: Int
    let currentPage: Int
    let onPageSelected: ((Int) -> Void)?
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.white : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .onTapGesture {
                        onPageSelected?(page)
                    }
            }
        }
        .padding(.vertical, 8)
    }
}
