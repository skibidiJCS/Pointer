import SwiftUI

struct StatusIndicator: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color.opacity(0.6), radius: 4)
    }
}
