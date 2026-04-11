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
    let url: URL
    /// Change in probability (0.0–1.0) since the last stored snapshot.
    /// Nil when no prior snapshot exists (e.g., first fetch).
    var priceChange: Double? = nil

    var probabilityPercent: Int {
        Int((probability * 100).rounded())
    }

    /// Absolute change in percentage points, e.g. 0.023 → 2 (for "2pp").
    var priceChangePoints: Int? {
        priceChange.map { Int(($0 * 100).rounded()) }
    }

    /// Classified direction: .up / .down / .flat / nil (unknown).
    /// Uses a 1pp dead-zone so noise doesn't light up arrows.
    var trend: Trend? {
        guard let change = priceChange else { return nil }
        if change >= 0.01 { return .up }
        if change <= -0.01 { return .down }
        return .flat
    }

    enum Trend {
        case up, down, flat
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
