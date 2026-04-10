import Foundation

struct Market: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let question: String
    let probability: Double
    let volume24h: Double
    let totalVolume: Double
    let category: MarketCategory
    let source: MarketSource
    let endDate: Date?

    var probabilityPercent: Int {
        Int((probability * 100).rounded())
    }

    var formattedVolume: String {
        if volume24h >= 1_000_000 {
            return String(format: "$%.1fM", volume24h / 1_000_000)
        } else if volume24h >= 1_000 {
            return String(format: "$%.0fK", volume24h / 1_000)
        }
        return String(format: "$%.0f", volume24h)
    }
}

enum MarketSource: String, Codable, Hashable, Sendable {
    case polymarket = "Polymarket"
    case kalshi = "Kalshi"
}
