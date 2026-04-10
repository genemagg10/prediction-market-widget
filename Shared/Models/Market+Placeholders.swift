import Foundation

extension Market {
    static var placeholders: [Market] {
        [
            Market(id: "1", question: "Will BTC exceed $120K before July 2025?", probability: 0.71,
                   volume24h: 1_250_000, totalVolume: 5_000_000, category: .crypto, source: .polymarket,
                   endDate: nil, url: URL(string: "https://polymarket.com")!),
            Market(id: "2", question: "Federal Reserve cuts rates in Q2 2025?", probability: 0.42,
                   volume24h: 890_000, totalVolume: 12_000_000, category: .finance, source: .kalshi,
                   endDate: nil, url: URL(string: "https://kalshi.com")!),
            Market(id: "3", question: "Will the Lakers make the 2025 playoffs?", probability: 0.61,
                   volume24h: 320_000, totalVolume: 1_100_000, category: .sports, source: .kalshi,
                   endDate: nil, url: URL(string: "https://kalshi.com")!),
            Market(id: "4", question: "GPT-5 released before end of 2025?", probability: 0.55,
                   volume24h: 450_000, totalVolume: 2_300_000, category: .science, source: .polymarket,
                   endDate: nil, url: URL(string: "https://polymarket.com")!),
            Market(id: "5", question: "Will SpaceX reach Mars orbit in 2026?", probability: 0.28,
                   volume24h: 210_000, totalVolume: 800_000, category: .science, source: .polymarket,
                   endDate: nil, url: URL(string: "https://polymarket.com")!),
            Market(id: "6", question: "ETH above $5K by year end?", probability: 0.48,
                   volume24h: 670_000, totalVolume: 3_400_000, category: .crypto, source: .polymarket,
                   endDate: nil, url: URL(string: "https://polymarket.com")!),
            Market(id: "7", question: "Next UK election before 2027?", probability: 0.33,
                   volume24h: 180_000, totalVolume: 540_000, category: .politics, source: .kalshi,
                   endDate: nil, url: URL(string: "https://kalshi.com")!),
            Market(id: "8", question: "Apple announces AR glasses in 2025?", probability: 0.22,
                   volume24h: 140_000, totalVolume: 420_000, category: .science, source: .polymarket,
                   endDate: nil, url: URL(string: "https://polymarket.com")!),
        ]
    }
}
