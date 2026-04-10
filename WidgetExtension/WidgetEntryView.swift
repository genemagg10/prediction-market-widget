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
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 4)

            Divider()
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: isLarge ? 4 : 6) {
                ForEach(marketsToShow) { market in
                    rowView(for: market)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(.background, for: .widget)
        // In small widgets only one URL is supported; tap anywhere opens the top market.
        .widgetURL(family == .systemSmall ? marketsToShow.first?.url : nil)
    }

    private var isLarge: Bool { family == .systemLarge }

    private var header: some View {
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
    }

    @ViewBuilder
    private func rowView(for market: Market) -> some View {
        let row = WidgetMarketRow(market: market, style: rowStyle)
        if family != .systemSmall {
            // Medium and large support multiple Link taps per widget.
            Link(destination: market.url) { row }
        } else {
            row
        }
    }

    private var rowStyle: WidgetMarketRow.Style {
        switch family {
        case .systemSmall:  return .compact
        case .systemLarge:  return .dense
        default:            return .standard
        }
    }
}

// MARK: - Widget row

struct WidgetMarketRow: View {
    enum Style { case compact, standard, dense }

    let market: Market
    let style: Style

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(market.source == .polymarket ? Color.purple : Color.green)
                .frame(width: 6, height: 6)

            Text(market.question)
                .font(questionFont)
                .lineLimit(lineLimit)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(market.probabilityPercent)%")
                    .font(probabilityFont)
                    .monospacedDigit()
                    .foregroundStyle(probabilityColor(market.probability))
                if style == .standard {
                    Text(market.formattedVolume)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var questionFont: Font {
        switch style {
        case .compact:  return .caption
        case .standard: return .caption
        case .dense:    return .caption2
        }
    }

    private var probabilityFont: Font {
        switch style {
        case .compact:  return .caption.bold()
        case .standard: return .caption.bold()
        case .dense:    return .caption2.bold()
        }
    }

    private var lineLimit: Int {
        switch style {
        case .compact:  return 1
        case .standard: return 2
        case .dense:    return 2
        }
    }

    private func probabilityColor(_ p: Double) -> Color {
        p >= 0.65 ? .green : p >= 0.4 ? .orange : .red
    }
}
