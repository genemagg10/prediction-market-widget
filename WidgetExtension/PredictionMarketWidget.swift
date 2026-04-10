import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct MarketEntry: TimelineEntry {
    let date: Date
    let markets: [Market]
    let category: MarketCategory
}

// MARK: - Timeline provider

struct PredictionMarketProvider: AppIntentTimelineProvider {
    typealias Entry = MarketEntry
    typealias Intent = CategoryIntent

    func placeholder(in context: Context) -> MarketEntry {
        MarketEntry(date: .now, markets: Market.placeholders, category: .trending)
    }

    func snapshot(for configuration: CategoryIntent, in context: Context) async -> MarketEntry {
        MarketEntry(date: .now, markets: Market.placeholders, category: configuration.category)
    }

    func timeline(for configuration: CategoryIntent, in context: Context) async -> Timeline<MarketEntry> {
        let markets = await MarketService.shared.fetchAll(category: configuration.category)
        let entry = MarketEntry(date: .now, markets: markets, category: configuration.category)

        // Refresh every 15 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        return Timeline(entries: [entry], policy: .after(next))
    }
}
