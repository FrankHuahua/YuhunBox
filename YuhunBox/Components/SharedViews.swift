import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let symbol: String
    var tint: Color = .crimson

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 14)
    }
}

struct GradeBadge: View {
    let grade: String
    let score: Int

    private var tint: Color {
        switch grade {
        case "S": return .purple
        case "A": return .crimson
        case "B": return .orange
        case "C": return .blue
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(grade).font(.caption.weight(.black))
            Text("\(score)").font(.caption.monospacedDigit())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule())
        .accessibilityLabel("评级 \(grade)，\(score) 分")
    }
}

struct SoulRow: View {
    let soul: SoulPiece
    var score: SoulScore? = nil

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(soul.set.tint.opacity(0.14))
                Text("\(soul.slot.rawValue)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(soul.set.tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(soul.set.rawValue).font(.headline)
                    if soul.isLocked {
                        Image(systemName: "lock.fill").font(.caption2).foregroundStyle(Color.saffron)
                    }
                }
                Text("\(soul.mainStat.type.title) \(soul.mainStat.type.formatted(soul.mainStat.value)) · +\(soul.level)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !soul.substats.isEmpty {
                    Text(soul.substats.prefix(3).map { "\($0.type.shortTitle) \($0.type.formatted($0.value))" }.joined(separator: "  "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let score {
                GradeBadge(grade: score.grade, score: score.score)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 5)
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.crimson)
            Text(title).font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct TagView: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.1), in: Capsule())
    }
}

struct ModuleNavLabel: View {
    let title: String
    let detail: String
    let symbol: String
    var tint: Color = .crimson

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(width: 205, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.055), lineWidth: 1)
        }
    }
}

