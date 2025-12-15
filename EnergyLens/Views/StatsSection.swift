import SwiftUI

struct StatsSection: View {
    let readings: [Reading]
    
    private var daysBetweenText: String {
        let sorted = readings.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last, first.date < last.date else { return "-" }
        let days = last.date.timeIntervalSince(first.date) / 86400
        return String(format: "%.0f", days)
    }
    
    private var averageText: String {
        StatsCalculator.calculateAverage(readings)
    }
    
    private var yearEndText: String {
        StatsCalculator.calculateYearEndPrediction(readings)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            StatCard(title: NSLocalizedString("Days", comment: ""), value: daysBetweenText, unit: NSLocalizedString("days", comment: ""))
            Divider()
                .padding(.horizontal)
            StatCard(title: NSLocalizedString("Average", comment: ""), value: averageText, unit: NSLocalizedString("kWh/day", comment: ""))
            Divider()
                .padding(.horizontal)
            StatCard(title: NSLocalizedString("Year End Prediction", comment: ""), value: yearEndText, unit: NSLocalizedString("kWh", comment: ""))
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
