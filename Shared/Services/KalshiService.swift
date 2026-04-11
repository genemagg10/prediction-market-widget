import Foundation

// Kalshi's `/markets` endpoint returns tens of thousands of derivative /
// multi-leg markets that are mostly unpriced. The `/events` endpoint with
// `with_nested_markets=true` returns the curated parent events with their
// actively-priced child markets, and also exposes a `category` per event
// which we use to map to our MarketCategory enum.

struct KalshiService: Sendable {
    private let baseURL = "https://api.elections.kalshi.com/trade-api/v2"

    func fetchMarkets(category: MarketCategory) async throws -> [Market] {
        var components = URLComponents(string: "\(baseURL)/events")!
        components.queryItems = [
            URLQueryItem(name: "status", value: "open"),
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(name: "with_nested_markets", value: "true"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }

        let decoded = try JSONDecoder().decode(KalshiEventsResponse.self, from: data)
        return decoded.events.flatMap { $0.toMarkets(requestedCategory: category) }
    }
}

// MARK: - Private decoding types

private struct KalshiEventsResponse: Codable {
    let events: [RawEvent]
}

private struct RawEvent: Codable {
    let eventTicker: String
    let seriesTicker: String?
    let title: String
    let category: String?
    let markets: [RawMarket]?

    enum CodingKeys: String, CodingKey {
        case title, category, markets
        case eventTicker = "event_ticker"
        case seriesTicker = "series_ticker"
    }

    func toMarkets(requestedCategory: MarketCategory) -> [Market] {
        guard let markets else { return [] }

        let cat: MarketCategory = requestedCategory == .trending
            ? mapCategory(category ?? "")
            : requestedCategory

        // Kalshi market page URL is https://kalshi.com/markets/<series>/<event-slug>
        // The series slug is the lowercased series ticker (or first segment of
        // the event ticker if series_ticker is absent).
        let seriesSource = seriesTicker ?? eventTicker
        let series = seriesSource
            .split(separator: "-")
            .first
            .map(String.init)?
            .lowercased() ?? ""
        let eventURL = URL(string: "https://kalshi.com/markets/\(series)")
            ?? URL(string: "https://kalshi.com")!

        return markets.compactMap { $0.toMarket(category: cat, url: eventURL) }
    }

    private func mapCategory(_ raw: String) -> MarketCategory {
        let s = raw.lowercased()
        if s.contains("polit") || s.contains("elect") { return .politics }
        if s.contains("sport") || s.contains("nba") || s.contains("nfl") || s.contains("mlb") || s.contains("nhl") || s.contains("soccer") { return .sports }
        if s.contains("crypto") || s.contains("bitcoin") || s.contains("eth") { return .crypto }
        if s.contains("financ") || s.contains("econ") || s.contains("fed") { return .finance }
        if s.contains("sci") || s.contains("tech") || s.contains("ai") || s.contains("climate") || s.contains("space") { return .science }
        if s.contains("entertain") || s.contains("movie") || s.contains("music") || s.contains("award") { return .entertainment }
        return .other
    }
}

private struct RawMarket: Codable {
    let ticker: String
    let title: String
    // All numeric fields on the v2 /events endpoint are strings.
    let yesAskDollars: String?
    let yesBidDollars: String?
    let lastPriceDollars: String?
    let previousYesBidDollars: String?
    let previousYesAskDollars: String?
    let volumeFp: String?
    let volume24hFp: String?
    let closeTime: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case ticker, title, status
        case yesAskDollars        = "yes_ask_dollars"
        case yesBidDollars        = "yes_bid_dollars"
        case lastPriceDollars     = "last_price_dollars"
        case previousYesBidDollars = "previous_yes_bid_dollars"
        case previousYesAskDollars = "previous_yes_ask_dollars"
        case volumeFp             = "volume_fp"
        case volume24hFp          = "volume_24h_fp"
        case closeTime            = "close_time"
    }

    func toMarket(category: MarketCategory, url: URL) -> Market? {
        // Kalshi calls open markets "active" in the v2 API.
        guard status == "active" else { return nil }

        // Parse current probability from last_price, falling back to the
        // bid/ask midpoint. Values on the /events endpoint are in dollars
        // (0.0000–1.0000), so no /100 conversion.
        let prob: Double
        if let last = lastPriceDollars.flatMap(Double.init), last > 0 {
            prob = min(max(last, 0), 1)
        } else if let ask = yesAskDollars.flatMap(Double.init),
                  let bid = yesBidDollars.flatMap(Double.init),
                  (ask + bid) > 0 {
            prob = min(max((ask + bid) / 2, 0), 1)
        } else {
            return nil
        }

        // Compute 24h trend from previous bid/ask midpoint when available.
        let change: Double?
        if let prevAsk = previousYesAskDollars.flatMap(Double.init),
           let prevBid = previousYesBidDollars.flatMap(Double.init),
           (prevAsk + prevBid) > 0 {
            change = prob - ((prevAsk + prevBid) / 2)
        } else {
            change = nil
        }

        let volume24h = volume24hFp.flatMap(Double.init) ?? 0
        let totalVol = volumeFp.flatMap(Double.init) ?? 0
        let endDate: Date? = closeTime.flatMap { ISO8601DateFormatter().date(from: $0) }

        return Market(
            id: "kalshi-\(ticker)",
            question: title,
            probability: prob,
            volume24h: volume24h,
            totalVolume: totalVol,
            category: category,
            source: .kalshi,
            endDate: endDate,
            url: url,
            priceChange: change
        )
    }
}
