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
        return Array(combined.prefix(25))
    }

    private func fetchSafely(_ block: @Sendable () async throws -> [Market]) async -> [Market] {
        (try? await block()) ?? []
    }
}
