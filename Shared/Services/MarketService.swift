import Foundation

struct MarketService: Sendable {
    static let shared = MarketService()

    private let polymarket = PolymarketService()
    private let kalshi = KalshiService()

    private let kalshiKeyDefault = "com.genemagg10.PredictionMarketWidget.kalshiKey"

    func fetchAll(category: MarketCategory) async -> [Market] {
        let kalshiKey = UserDefaults.standard.string(forKey: kalshiKeyDefault) ?? ""

        async let polyFetch = fetchSafely { try await polymarket.fetchMarkets(category: category) }
        async let kalshiFetch = fetchSafely { try await kalshi.fetchMarkets(category: category, apiKey: kalshiKey) }

        var combined = await polyFetch + kalshiFetch

        // For category filters, narrow down by category tag
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
