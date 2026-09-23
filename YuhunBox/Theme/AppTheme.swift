import SwiftUI

enum AppTheme {
    static let page = Color(red: 0.025, green: 0.03, blue: 0.045)
    static let card = Color(red: 0.075, green: 0.085, blue: 0.115)
    static let elevated = Color(red: 0.105, green: 0.115, blue: 0.15)
    static let muted = Color.white.opacity(0.62)
    static let separator = Color.white.opacity(0.09)
    static let cyan = Color(red: 0.18, green: 0.90, blue: 0.94)
    static let pink = Color(red: 1.00, green: 0.15, blue: 0.39)
    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.035, green: 0.07, blue: 0.13), Color(red: 0.23, green: 0.045, blue: 0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accentGradient = LinearGradient(
        colors: [cyan, pink],
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
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.055), lineWidth: 1)
            }
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
                .fill(Color.ink)
            Image(systemName: "snowflake")
                .font(.system(size: size * 0.50, weight: .bold))
                .foregroundStyle(AppTheme.cyan)
                .offset(x: -size * 0.035, y: -size * 0.025)
            Image(systemName: "snowflake")
                .font(.system(size: size * 0.50, weight: .bold))
                .foregroundStyle(AppTheme.pink.opacity(0.72))
                .offset(x: size * 0.055, y: size * 0.045)
                .blendMode(.screen)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

