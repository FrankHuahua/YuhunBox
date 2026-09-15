import SwiftUI

enum AppTheme {
    static let page = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let muted = Color(uiColor: .secondaryLabel)
    static let separator = Color(uiColor: .separator).opacity(0.4)
    static let heroGradient = LinearGradient(
        colors: [Color.ink, Color(red: 0.28, green: 0.09, blue: 0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

struct SectionHeading: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AppMark: View {
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: [.crimson, Color(red: 0.38, green: 0.05, blue: 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .stroke(Color.saffron.opacity(0.85), lineWidth: max(1, size * 0.035))
                .padding(size * 0.20)
            Circle()
                .fill(Color.saffron)
                .frame(width: size * 0.17, height: size * 0.17)
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(Color.saffron.opacity(0.9))
                    .frame(width: size * 0.08, height: size * 0.22)
                    .offset(y: -size * 0.27)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}


