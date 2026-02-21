import SwiftUI

struct EditModeOverlay: ViewModifier {
    let isEditing: Bool
    let canDelete: Bool
    let onDelete: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if isEditing && canDelete {
                    deleteButton
                }
            }
            .shakeAnimation(isShaking: isEditing)
    }
    
    private var deleteButton: some View {
        Button {
            onDelete?()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)
                .background(Circle().fill(.white))
        }
        .buttonStyle(.plain)
        .offset(x: -8, y: -8)
    }
}

extension View {
    func editMode(isEditing: Bool, canDelete: Bool = true, onDelete: (() -> Void)? = nil) -> some View {
        modifier(EditModeOverlay(isEditing: isEditing, canDelete: canDelete, onDelete: onDelete))
    }
    
    func shakeAnimation(isShaking: Bool) -> some View {
        modifier(ShakeModifier(isShaking: isShaking))
    }
}

struct ShakeModifier: ViewModifier {
    let isShaking: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isShaking ? Foundation.sin(phase) * 2 : 0))
            .onAppear {
                if isShaking {
                    withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: true)) {
                        phase = .pi
                    }
                }
            }
            .onChange(of: isShaking) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: true)) {
                        phase = .pi
                    }
                } else {
                    phase = 0
                }
            }
    }
}
