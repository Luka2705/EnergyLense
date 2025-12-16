import Foundation

enum StatsCalculator {
    
    /// Calculates average daily consumption in kWh/day
    static func calculateAverage(_ readings: [Reading]) -> String {
        let sorted = readings.sorted { $0.date < $1.date }
        guard sorted.count >= 2,
              let first = sorted.first,
              let last = sorted.last else { return "-" }
        
        let days = last.date.timeIntervalSince(first.date) / 86400
        if days <= 0 { return "-" }
        
        let totalConsumption = last.value - first.value
        let avgDaily = totalConsumption / days
        return String(format: "%.1f", avgDaily)
    }
    
    /// Calculates predicted meter reading at year end
    static func calculateYearEndPrediction(_ readings: [Reading]) -> String {
        let sorted = readings.sorted { $0.date < $1.date }
        guard sorted.count >= 2, let oldest = sorted.first, let youngest = sorted.last else { return "-" }

        // Compute time delta in hours between oldest and youngest readings (robust against tiny negatives)
        let epsilon: Double = 1e-6
        let hoursDeltaRaw = youngest.date.timeIntervalSince(oldest.date) / 3600.0
        let hoursDelta = max(0, hoursDeltaRaw)
        guard hoursDelta > epsilon else { return "-" }

        // Compute consumption delta in kWh between the two readings
        let kWhDelta = youngest.value - oldest.value
        guard kWhDelta >= 0 else { return "-" }

        // Average consumption rate in kWh per hour
        let kWhPerHour = kWhDelta / hoursDelta

        // Use 8760 hours (non-leap year) for annual scaling as requested
        let annualHours: Double = 8760
        let predictedAnnualConsumption = kWhPerHour * annualHours

        return String(format: "%.0f", predictedAnnualConsumption)
    }
    
    /// Calculates predicted consumption for next month
    static func calculateMonthlyPrediction(_ readings: [Reading]) -> String {
        let sorted = readings.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return "-" }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Use last 30 days if available
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let recent = sorted.filter { $0.date >= thirtyDaysAgo }
        
        let avgDaily: Double
        if recent.count >= 2 {
            let first = recent.first!
            let last = recent.last!
            let days = last.date.timeIntervalSince(first.date) / 86400
            if days > 0 {
                avgDaily = (last.value - first.value) / days
            } else {
                return "-"
            }
        } else {
            let first = sorted.first!
            let last = sorted.last!
            let days = last.date.timeIntervalSince(first.date) / 86400
            if days > 0 {
                avgDaily = (last.value - first.value) / days
            } else {
                return "-"
            }
        }
        
        // Predict consumption for next 30 days
        let monthlyConsumption = avgDaily * 30
        return String(format: "%.0f", monthlyConsumption)
    }
}


