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

        var polyMarkets = await polyFetch
        var kalshiMarkets = await kalshiFetch

        if category != .trending {
            polyMarkets = polyMarkets.filter { $0.category == category }
            kalshiMarkets = kalshiMarkets.filter { $0.category == category }
        }

        // Rank each source by 24h volume within itself. We can't just merge
        // and sort globally — Polymarket markets trade at ~100x the dollar
        // volume of Kalshi, so a global sort pushes every Kalshi market off
        // the end and the widget ends up Polymarket-only.
        polyMarkets.sort { $0.volume24h > $1.volume24h }
        kalshiMarkets.sort { $0.volume24h > $1.volume24h }

        // Round-robin interleave so both sources appear in any top-N view.
        let topPoly = Array(polyMarkets.prefix(15))
        let topKalshi = Array(kalshiMarkets.prefix(15))
        var combined: [Market] = []
        combined.reserveCapacity(topPoly.count + topKalshi.count)
        for i in 0..<Swift.max(topPoly.count, topKalshi.count) {
            if i < topPoly.count { combined.append(topPoly[i]) }
            if i < topKalshi.count { combined.append(topKalshi[i]) }
        }

        return Self.annotateWithTrends(Array(combined.prefix(25)))
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

            // Always keep the snapshot store fresh for eviction, and as a
            // fallback source for markets whose API didn't provide a trend.
            if let prev = store[market.id] {
                if m.priceChange == nil {
                    m.priceChange = market.probability - prev.probability
                }
                if now.timeIntervalSince(prev.timestamp) >= minimumSnapshotAge {
                    store[market.id] = Snapshot(probability: market.probability, timestamp: now)
                }
            } else {
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
