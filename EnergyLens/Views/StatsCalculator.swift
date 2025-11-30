import Foundation

enum StatsCalculator {
    
    static func calculateAverage(_ readings: [Reading]) -> String {
        let sorted = readings.sorted { $0.date < $1.date }
        guard sorted.count >= 2,
              let first = sorted.first,
              let last = sorted.last else { return "-" }
        
        let days = last.date.timeIntervalSince(first.date) / 86400
        if days <= 0 { return "-" }
        
        let avg = (last.value - first.value) / days
        return String(format: "%.1f", avg)
    }
    
    static func calculateYearEndPrediction(_ readings: [Reading]) -> String {
        let sorted = readings.sorted { $0.date < $1.date }
        guard let last = sorted.last else { return "-" }
        
        let now = Date()
        let calendar = Calendar.current
        
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let recent = sorted.filter { $0.date >= thirtyDaysAgo }
        
        let avgDaily: Double = {
            if recent.count >= 2 {
                let first = recent.first!
                let last = recent.last!
                let days = last.date.timeIntervalSince(first.date) / 86400
                if days > 0 { return (last.value - first.value) / days }
            }
            return Double(calculateAverage(sorted)) ?? 0
        }()
        
        let endOfYear = calendar.date(from:
            DateComponents(year: calendar.component(.year, from: now), month: 12, day: 31)
        )!
        
        let daysRemaining = max(0, endOfYear.timeIntervalSince(last.date) / 86400)
        let predicted = last.value + avgDaily * daysRemaining
        
        return String(format: "%.0f", predicted)
    }
}

