import AppIntents

enum MarketCategory: String, CaseIterable, Codable, Hashable, Sendable, AppEnum {
    case trending     = "Trending"
    case politics     = "Politics"
    case sports       = "Sports"
    case crypto       = "Crypto"
    case finance      = "Finance"
    case science      = "Science"
    case entertainment = "Entertainment"
    case other        = "Other"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var caseDisplayRepresentations: [MarketCategory: DisplayRepresentation] = [
        .trending:      "Trending",
        .politics:      "Politics",
        .sports:        "Sports",
        .crypto:        "Crypto",
        .finance:       "Finance",
        .science:       "Science",
        .entertainment: "Entertainment",
        .other:         "Other",
    ]

    var systemImage: String {
        switch self {
        case .trending:      return "chart.line.uptrend.xyaxis"
        case .politics:      return "building.columns"
        case .sports:        return "sportscourt"
        case .crypto:        return "bitcoinsign.circle"
        case .finance:       return "dollarsign.circle"
        case .science:       return "flask"
        case .entertainment: return "popcorn"
        case .other:         return "ellipsis.circle"
        }
    }
}
