import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var fetcher = MarketFetcher()
    @State private var selectedCategory: MarketCategory = .trending

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Prediction Markets")
                    .font(.title2.bold())
                Spacer()
                Button {
                    fetcher.refreshWidget()
                    Task { await fetcher.fetch(category: selectedCategory) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh markets and reload widget")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Category picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MarketCategory.allCases, id: \.self) { cat in
                        CategoryChip(category: cat, isSelected: selectedCategory == cat) {
                            selectedCategory = cat
                            Task { await fetcher.fetch(category: cat) }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            Divider()

            // Market list
            if fetcher.isLoading {
                ProgressView("Loading markets…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if fetcher.markets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No markets found")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(fetcher.markets) { market in
                    MarketListRow(market: market)
                        .listRowSeparator(.visible)
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 540, idealWidth: 620, minHeight: 420, idealHeight: 520)
        .task {
            await fetcher.fetch(category: selectedCategory)
        }
    }
}

// MARK: - Category chip

struct CategoryChip: View {
    let category: MarketCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.systemImage)
                Text(category.rawValue)
            }
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Market row

struct MarketListRow: View {
    let market: Market

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    SourceBadge(source: market.source)
                    Text(market.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(market.question)
                    .font(.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(market.probabilityPercent)%")
                    .font(.title3.bold())
                    .foregroundStyle(probabilityColor(market.probability))
                Text(market.formattedVolume)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    private func probabilityColor(_ p: Double) -> Color {
        p >= 0.65 ? .green : p >= 0.4 ? .orange : .red
    }
}

// MARK: - Source badge

struct SourceBadge: View {
    let source: MarketSource

    var body: some View {
        Text(source.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(source == .polymarket ? Color.purple.opacity(0.15) : Color.green.opacity(0.15))
            .foregroundStyle(source == .polymarket ? Color.purple : Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
