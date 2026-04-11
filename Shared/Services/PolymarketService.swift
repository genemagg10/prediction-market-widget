import Foundation

struct PolymarketService: Sendable {
    private let baseURL = "https://gamma-api.polymarket.com"

    func fetchMarkets(category: MarketCategory) async throws -> [Market] {
        var components = URLComponents(string: "\(baseURL)/markets")!
        components.queryItems = [
            URLQueryItem(name: "active", value: "true"),
            URLQueryItem(name: "closed", value: "false"),
            URLQueryItem(name: "limit", value: "40"),
            URLQueryItem(name: "order", value: "volume24hr"),
            URLQueryItem(name: "ascending", value: "false"),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let raw = try JSONDecoder().decode([RawMarket].self, from: data)
        return raw.compactMap { $0.toMarket(requestedCategory: category) }
    }
}

// MARK: - Private decoding types

private struct RawMarket: Codable {
    let id: String
    let question: String
    let slug: String?
    let outcomePrices: String?   // JSON-encoded string: "[\"0.64\",\"0.36\"]"
    let volume24hr: Double?
    // Polymarket returns total `volume` as a string like "7772042.67". Decode
    // as String? and parse manually — decoding as Double? throws typeMismatch
    // and kills the whole response.
    let volume: String?
    let oneDayPriceChange: Double?
    let tags: [RawTag]?
    // `endDate` is a full ISO-8601 datetime; `endDateIso` is a date-only
    // string. Prefer the former so ISO8601DateFormatter actually parses it.
    let endDate: String?
    let active: Bool?
    let closed: Bool?

    func toMarket(requestedCategory: MarketCategory) -> Market? {
        guard active == true, closed == false else { return nil }

        let prob: Double
        if let raw = outcomePrices,
           let data = raw.data(using: .utf8),
           let prices = try? JSONDecoder().decode([String].self, from: data),
           let first = prices.first,
           let p = Double(first) {
            prob = min(max(p, 0), 1)
        } else {
            prob = 0.5
        }

        let endDateParsed: Date? = endDate.flatMap { ISO8601DateFormatter().date(from: $0) }
        let totalVol = volume.flatMap(Double.init) ?? 0

        let category = requestedCategory == .trending
            ? detectCategory(from: tags)
            : requestedCategory

        let marketURL: URL = {
            if let slug, let url = URL(string: "https://polymarket.com/event/\(slug)") {
                return url
            }
            return URL(string: "https://polymarket.com")!
        }()

        return Market(
            id: "poly-\(id)",
            question: question,
            probability: prob,
            volume24h: volume24hr ?? 0,
            totalVolume: totalVol,
            category: category,
            source: .polymarket,
            endDate: endDateParsed,
            url: marketURL,
            priceChange: oneDayPriceChange
        )
    }

    private func detectCategory(from tags: [RawTag]?) -> MarketCategory {
        let labels = (tags ?? []).flatMap { [$0.label, $0.slug] }.compactMap { $0?.lowercased() }
        if labels.contains(where: { $0.contains("polit") || $0.contains("elect") }) { return .politics }
        if labels.contains(where: { $0.contains("sport") || $0.contains("nba") || $0.contains("nfl") || $0.contains("soccer") || $0.contains("mlb") || $0.contains("nhl") }) { return .sports }
        if labels.contains(where: { $0.contains("crypto") || $0.contains("bitcoin") || $0.contains("eth") }) { return .crypto }
        if labels.contains(where: { $0.contains("financ") || $0.contains("stock") || $0.contains("econ") }) { return .finance }
        if labels.contains(where: { $0.contains("sci") || $0.contains("tech") || $0.contains("ai") || $0.contains("space") }) { return .science }
        if labels.contains(where: { $0.contains("entertain") || $0.contains("movie") || $0.contains("music") || $0.contains("award") }) { return .entertainment }
        return .other
    }
}

private struct RawTag: Codable {
    let label: String?
    let slug: String?
}
