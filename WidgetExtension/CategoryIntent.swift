import AppIntents

struct CategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Prediction Markets"
    static var description = IntentDescription("Choose which category of prediction markets to display.")

    @Parameter(title: "Category", default: MarketCategory.trending)
    var category: MarketCategory
}
