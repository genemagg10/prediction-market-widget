import Foundation

/// App Group identifier — must match the entitlement declared in `project.yml`
/// for both the app and widget extension targets.
enum AppGroup {
    static let identifier = "group.com.genemagg10.PredictionMarketWidget"

    /// Shared UserDefaults visible to both the app and the widget extension.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

struct MarketService: Sendable {
    static let shared = MarketService()

    private let polymarket = PolymarketService()
    private let kalshi = KalshiService()

    func fetchAll(category: MarketCategory) async -> [Market] {
        async let polyFetch = fetchSafely { try await polymarket.fetchMarkets(category: category) }
        async let kalshiFetch = fetchSafely { try await kalshi.fetchMarkets(category: category) }

        var combined = await polyFetch + kalshiFetch

        // For category filters, narrow down by detected category
        if category != .trending {
            combined = combined.filter { $0.category == category }
        }

        // Sort by 24h volume descending
        combined.sort { $0.volume24h > $1.volume24h }
        let top = Array(combined.prefix(25))
        return Self.annotateWithTrends(top)
    }

    private func fetchSafely(_ block: @Sendable () async throws -> [Market]) async -> [Market] {
        (try? await block()) ?? []
    }

    // MARK: - Trend snapshots

    private static let snapshotKey = "marketSnapshots_v1"
    /// Keep the "previous" anchor frozen for at least this long so rapid
    /// refreshes (widget polls every 15 min) still yield meaningful deltas.
    private static let minimumSnapshotAge: TimeInterval = 60 * 60 // 1 hour

    private struct Snapshot: Codable {
        let probability: Double
        let timestamp: Date
    }

    /// Annotates each market with a `priceChange` based on a snapshot stored
    /// in the shared App Group. Markets are returned in the same order.
    private static func annotateWithTrends(_ markets: [Market]) -> [Market] {
        let defaults = AppGroup.defaults
        var store: [String: Snapshot] = {
            guard let data = defaults.data(forKey: snapshotKey),
                  let decoded = try? JSONDecoder().decode([String: Snapshot].self, from: data)
            else { return [:] }
            return decoded
        }()

        let now = Date()
        var annotated: [Market] = []
        annotated.reserveCapacity(markets.count)

        for market in markets {
            var m = market
            if let prev = store[market.id] {
                m.priceChange = market.probability - prev.probability
                // Only advance the anchor once it's aged past the minimum window.
                if now.timeIntervalSince(prev.timestamp) >= minimumSnapshotAge {
                    store[market.id] = Snapshot(probability: market.probability, timestamp: now)
                }
            } else {
                // First time seeing this market — seed the anchor, leave priceChange nil.
                store[market.id] = Snapshot(probability: market.probability, timestamp: now)
            }
            annotated.append(m)
        }

        // Evict entries older than 7 days so the store doesn't grow unbounded.
        let cutoff = now.addingTimeInterval(-60 * 60 * 24 * 7)
        store = store.filter { $0.value.timestamp > cutoff }

        if let data = try? JSONEncoder().encode(store) {
            defaults.set(data, forKey: snapshotKey)
        }

        return annotated
    }
}
