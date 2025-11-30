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
        guard let last = sorted.last else { return "-" }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate average daily consumption from last 30 days if available
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let recent = sorted.filter { $0.date >= thirtyDaysAgo }
        
        let avgDaily: Double
        if recent.count >= 2 {
            // Use last 30 days average
            let first = recent.first!
            let last = recent.last!
            let days = last.date.timeIntervalSince(first.date) / 86400
            if days > 0 {
                avgDaily = (last.value - first.value) / days
            } else {
                return "-"
            }
        } else if sorted.count >= 2 {
            // Fall back to overall average
            let first = sorted.first!
            let last = sorted.last!
            let days = last.date.timeIntervalSince(first.date) / 86400
            if days > 0 {
                avgDaily = (last.value - first.value) / days
            } else {
                return "-"
            }
        } else {
            return "-"
        }
        
        // Calculate days remaining until end of year
        let endOfYear = calendar.date(from:
            DateComponents(year: calendar.component(.year, from: now), month: 12, day: 31, hour: 23, minute: 59)
        )!
        
        let daysRemaining = max(0, endOfYear.timeIntervalSince(now) / 86400)
        
        // Predicted meter reading = current reading + (avg daily * days remaining)
        let predicted = last.value + (avgDaily * daysRemaining)
        
        return String(format: "%.0f", predicted)
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


