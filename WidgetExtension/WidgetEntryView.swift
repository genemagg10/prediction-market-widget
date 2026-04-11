import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: MarketEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    private var marketsToShow: [Market] {
        switch family {
        case .systemSmall:  return Array(entry.markets.prefix(3))
        case .systemMedium: return Array(entry.markets.prefix(4))
        case .systemLarge:  return Array(entry.markets.prefix(8))
        default:            return Array(entry.markets.prefix(4))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 4)

            Divider()
                .opacity(0.4)
                .padding(.bottom, 4)

            ForEach(Array(marketsToShow.enumerated()), id: \.element.id) { index, market in
                if index > 0 {
                    Divider()
                        .opacity(0.35)
                }
                rowView(for: market)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: fillsVertically ? .infinity : nil,
                        alignment: .leading
                    )
            }

            if !fillsVertically {
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            glassBackground
        }
        // Small widgets only support a single URL — tap anywhere opens the top market.
        .widgetURL(family == .systemSmall ? marketsToShow.first?.url : nil)
    }

    private var isLarge: Bool { family == .systemLarge }
    private var fillsVertically: Bool { family == .systemLarge || family == .systemSmall }

    private var glassBackground: some View {
        ZStack {
            // Adaptive base that follows the system appearance.
            Color(nsColor: .windowBackgroundColor)

            // Soft liquid-glass gradient tint.
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.14),
                    Color.purple.opacity(colorScheme == .dark ? 0.18 : 0.10),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle top highlight for a glassy edge.
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.06 : 0.35),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.category.systemImage)
                .font(.caption.bold())
                .foregroundStyle(.blue)
            Text(entry.category.rawValue.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .kerning(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize()
        }
    }

    @ViewBuilder
    private func rowView(for market: Market) -> some View {
        let row = WidgetMarketRow(market: market, compact: family == .systemSmall)
        if family != .systemSmall {
            Link(destination: market.url) {
                row.contentShape(Rectangle())
            }
        } else {
            row
        }
    }
}

// MARK: - Widget row

struct WidgetMarketRow: View {
    let market: Market
    let compact: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(market.category.emoji)
                .font(.caption)

            VStack(alignment: .leading, spacing: 0) {
                Text(market.question)
                    .font(.caption)
                    .lineLimit(compact ? 1 : 2)
                    .foregroundStyle(.primary)
                if !compact {
                    Text(market.source.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 2) {
                    if let trend = market.trend {
                        TrendArrow(trend: trend)
                    }
                    Text("\(market.probabilityPercent)%")
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundStyle(probabilityColor(market.probability))
                }
                if !compact {
                    Text(market.formattedVolume)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func probabilityColor(_ p: Double) -> Color {
        p >= 0.65 ? .green : p >= 0.4 ? .orange : .red
    }
}

// MARK: - Trend arrow

struct TrendArrow: View {
    let trend: Market.Trend

    var body: some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.green)
        case .down:
            Image(systemName: "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.red)
        case .flat:
            Image(systemName: "minus")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }
}
