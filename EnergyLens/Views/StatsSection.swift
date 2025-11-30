import SwiftUI

struct StatsSection: View {
    let readings: [Reading]
    
    private var averageText: String {
        StatsCalculator.calculateAverage(readings)
    }
    
    private var yearEndText: String {
        StatsCalculator.calculateYearEndPrediction(readings)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            StatCard(title: "Average", value: averageText, unit: "kWh/day")
            StatCard(title: "Year End", value: yearEndText, unit: "kWh")
        }
        .padding(.horizontal)
    }
}
