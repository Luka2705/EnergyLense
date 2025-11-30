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
        VStack(spacing: 0) {
            StatCard(title: NSLocalizedString("Average", comment: ""), value: averageText, unit: NSLocalizedString("kWh/day", comment: ""))
            
            Divider()
                .padding(.horizontal)
            
            StatCard(title: NSLocalizedString("Year End Prediction", comment: ""), value: yearEndText, unit: NSLocalizedString("kWh", comment: ""))
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
