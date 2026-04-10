import Foundation
import WidgetKit

@MainActor
final class MarketFetcher: ObservableObject {
    @Published var markets: [Market] = []
    @Published var isLoading = false

    func fetch(category: MarketCategory) async {
        isLoading = true
        markets = await MarketService.shared.fetchAll(category: category)
        isLoading = false
    }

    func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
