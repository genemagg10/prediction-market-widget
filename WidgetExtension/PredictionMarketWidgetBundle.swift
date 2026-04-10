import WidgetKit
import SwiftUI

@main
struct PredictionMarketWidgetBundle: WidgetBundle {
    var body: some Widget {
        PredictionMarketWidgetMain()
    }
}

struct PredictionMarketWidgetMain: Widget {
    let kind = "PredictionMarketWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CategoryIntent.self,
            provider: PredictionMarketProvider()
        ) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prediction Markets")
        .description("Live odds from Polymarket and Kalshi, by category.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
