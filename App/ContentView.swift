import SwiftUI
import WidgetKit
import AppKit

struct ContentView: View {
    @StateObject private var fetcher = MarketFetcher()
    @State private var selectedCategory: MarketCategory = .trending

    var body: some View {
        ZStack {
            VisualEffectBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Toolbar — leave room for the traffic-light buttons since we hid the title bar.
                HStack {
                    Text("Prediction Markets")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        fetcher.refreshWidget()
                        Task { await fetcher.fetch(category: selectedCategory) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body.weight(.semibold))
                            .frame(width: 28, height: 28)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Refresh markets and reload widget")
                }
                .padding(.horizontal)
                .padding(.top, 28)
                .padding(.bottom, 12)

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
                .padding(.bottom, 10)

                Divider()
                    .opacity(0.4)

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
                        Link(destination: market.url) {
                            MarketListRow(market: market)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.visible)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .frame(minWidth: 540, idealWidth: 620, minHeight: 440, idealHeight: 540)
        .task {
            await fetcher.fetch(category: selectedCategory)
        }
    }
}

// MARK: - Visual effect background (real desktop blur)

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.accentColor.gradient)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.1),
                        lineWidth: 0.5
                    )
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .shadow(color: .black.opacity(isSelected ? 0.12 : 0), radius: 4, y: 1)
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
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.55)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func probabilityColor(_ p: Double) -> Color {
        p >= 0.65 ? .green : p >= 0.4 ? .orange : .red
    }
}

// MARK: - Source badge

struct SourceBadge: View {
    let source: MarketSource

    private var tint: Color {
        source == .polymarket ? .purple : .green
    }

    var body: some View {
        Text(source.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.5), lineWidth: 0.75)
            )
            .foregroundStyle(tint)
    }
}
