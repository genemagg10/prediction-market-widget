import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: MarketEntry
    @Environment(\.widgetFamily) var family

    private var marketsToShow: [Market] {
        switch family {
        case .systemSmall:  return Array(entry.markets.prefix(3))
        case .systemMedium: return Array(entry.markets.prefix(4))
        case .systemLarge:  return Array(entry.markets.prefix(8))
        default:            return Array(entry.markets.prefix(4))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: entry.category.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Text(entry.category.rawValue.uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .kerning(0.5)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()
                .padding(.vertical, 1)

            // Markets
            ForEach(Array(marketsToShow.enumerated()), id: \.element.id) { index, market in
                WidgetMarketRow(market: market, compact: family == .systemSmall)
                if index < marketsToShow.count - 1 {
                    Divider()
                        .padding(.vertical, 1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget row

struct WidgetMarketRow: View {
    let market: Market
    let compact: Bool

    var body: some View {
        HStack(spacing: 6) {
            // Source dot
            Circle()
                .fill(market.source == .polymarket ? Color.purple : Color.green)
                .frame(width: 6, height: 6)

            // Question text
            Text(market.question)
                .font(.caption)
                .lineLimit(compact ? 1 : 2)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Probability
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(market.probabilityPercent)%")
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(probabilityColor(market.probability))
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
