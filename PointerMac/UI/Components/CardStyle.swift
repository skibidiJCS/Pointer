import SwiftUI

struct PointerCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.primary.opacity(0.08))
            }
    }
}

extension View {
    func pointerCard() -> some View {
        modifier(PointerCardModifier())
    }
}
