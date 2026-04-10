import Foundation

// NOTE: Kalshi's public markets API requires an API key.
// Add your key in Settings (via the companion app) and it will be stored
// in UserDefaults so both the app and widget can access it.
// Without a key this service returns an empty array gracefully.

struct KalshiService: Sendable {
    private let baseURL = "https://trading-api.kalshi.com/trade-api/v2"

    func fetchMarkets(category: MarketCategory, apiKey: String) async throws -> [Market] {
        guard !apiKey.isEmpty else { return [] }

        var components = URLComponents(string: "\(baseURL)/markets")!
        components.queryItems = [
            URLQueryItem(name: "status", value: "open"),
            URLQueryItem(name: "limit", value: "40"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }

        let decoded = try JSONDecoder().decode(KalshiMarketsResponse.self, from: data)
        return decoded.markets.compactMap { $0.toMarket(requestedCategory: category) }
    }
}

// MARK: - Private decoding types

private struct KalshiMarketsResponse: Codable {
    let markets: [RawMarket]
}

private struct RawMarket: Codable {
    let ticker: String
    let title: String
    let yesAsk: Int?
    let yesBid: Int?
    let lastPrice: Int?
    let volume: Int?
    let volume24h: Int?
    let category: String?
    let closeTime: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case ticker, title, status, category, volume
        case yesAsk   = "yes_ask"
        case yesBid   = "yes_bid"
        case lastPrice = "last_price"
        case volume24h = "volume_24h"
        case closeTime = "close_time"
    }

    func toMarket(requestedCategory: MarketCategory) -> Market? {
        guard status == "open" else { return nil }

        // Kalshi prices are in cents (1–99)
        let prob: Double
        if let last = lastPrice, last > 0 {
            prob = Double(last) / 100.0
        } else if let ask = yesAsk, let bid = yesBid, (ask + bid) > 0 {
            prob = Double(ask + bid) / 200.0
        } else {
            prob = 0.5
        }

        let cat: MarketCategory = requestedCategory == .trending
            ? mapCategory(category ?? "")
            : requestedCategory

        let endDate: Date? = closeTime.flatMap { ISO8601DateFormatter().date(from: $0) }

        return Market(
            id: "kalshi-\(ticker)",
            question: title,
            probability: prob,
            volume24h: Double(volume24h ?? 0),
            totalVolume: Double(volume ?? 0),
            category: cat,
            source: .kalshi,
            endDate: endDate
        )
    }

    private func mapCategory(_ raw: String) -> MarketCategory {
        let s = raw.lowercased()
        if s.contains("polit") || s.contains("elect") { return .politics }
        if s.contains("sport") || s.contains("nba") || s.contains("nfl") { return .sports }
        if s.contains("crypto") || s.contains("bitcoin") { return .crypto }
        if s.contains("financ") || s.contains("econ") { return .finance }
        if s.contains("sci") || s.contains("tech") { return .science }
        if s.contains("entertain") { return .entertainment }
        return .other
    }
}
