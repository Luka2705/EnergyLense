import Foundation

enum ComparisonStatsCalculator {
    
    /// Calculates total consumption across all selected meters
    static func calculateTotalConsumption(for meterReadings: [String: [Reading]]) -> String {
        var total: Double = 0
        
        for (_, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            
            // Berechne die Summe aller Differenzen zwischen aufeinanderfolgenden Ablesungen
            for i in 0..<(sorted.count - 1) {
                let consumption = sorted[i + 1].value - sorted[i].value
                total += consumption
            }
        }
        
        return String(format: "%.0f", total)
    }
    
    /// Calculates average daily consumption across all meters
    static func calculateAverageDailyConsumption(for meterReadings: [String: [Reading]]) -> String {
        var totalConsumption: Double = 0
        var totalDays: Double = 0
        
        for (_, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }
            
            // Berechne Gesamtverbrauch für diesen Zähler
            var meterConsumption: Double = 0
            for i in 0..<(sorted.count - 1) {
                let consumption = sorted[i + 1].value - sorted[i].value
                meterConsumption += consumption
            }
            
            // Berechne die Zeitspanne vom ersten bis zum letzten Eintrag
            let first = sorted.first!
            let last = sorted.last!
            let days = last.date.timeIntervalSince(first.date) / 86400
            
            if days > 0 {
                totalConsumption += meterConsumption
                totalDays += days
            }
        }
        
        if totalDays > 0 {
            let avgDaily = totalConsumption / totalDays
            return String(format: "%.1f", avgDaily)
        }
        
        return "-"
    }
    
    /// Calculates which meter consumes the most
    static func findHighestConsumingMeter(for meterReadings: [String: [Reading]], meters: [Meter]) -> String {
        var maxConsumption: Double = 0
        var maxMeterId: String = ""
        
        for (meterId, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }
            
            // Berechne Gesamtverbrauch für diesen Zähler
            var consumption: Double = 0
            for i in 0..<(sorted.count - 1) {
                consumption += sorted[i + 1].value - sorted[i].value
            }
            
            if consumption > maxConsumption {
                maxConsumption = consumption
                maxMeterId = meterId
            }
        }
        
        if let meter = meters.first(where: { $0.meterNumber == maxMeterId }) {
            return meter.name
        }
        
        return "-"
    }
    
    /// Calculates predicted combined consumption for next month
    static func calculateCombinedMonthlyPrediction(for meterReadings: [String: [Reading]]) -> String {
        var totalMonthlyPrediction: Double = 0
        let now = Date()
        let calendar = Calendar.current
        
        for (_, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }
            
            // Versuche die letzten 30 Tage zu verwenden
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
            let recent = sorted.filter { $0.date >= thirtyDaysAgo }
            
            let avgDaily: Double
            
            if recent.count >= 2 {
                // Berechne Verbrauch der letzten 30 Tage
                var recentConsumption: Double = 0
                for i in 0..<(recent.count - 1) {
                    recentConsumption += recent[i + 1].value - recent[i].value
                }
                
                let first = recent.first!
                let last = recent.last!
                let days = last.date.timeIntervalSince(first.date) / 86400
                
                if days > 0 {
                    avgDaily = recentConsumption / days
                } else {
                    continue
                }
            } else {
                // Verwende alle verfügbaren Daten
                var totalConsumption: Double = 0
                for i in 0..<(sorted.count - 1) {
                    totalConsumption += sorted[i + 1].value - sorted[i].value
                }
                
                let first = sorted.first!
                let last = sorted.last!
                let days = last.date.timeIntervalSince(first.date) / 86400
                
                if days > 0 {
                    avgDaily = totalConsumption / days
                } else {
                    continue
                }
            }
            
            totalMonthlyPrediction += (avgDaily * 30)
        }
        
        return String(format: "%.0f", totalMonthlyPrediction)
    }
    
    /// Calculates percentage breakdown of consumption per meter
    static func calculateConsumptionPercentages(for meterReadings: [String: [Reading]], meters: [Meter]) -> [(name: String, percentage: Double)] {
        var consumptions: [(meterId: String, consumption: Double)] = []
        var totalConsumption: Double = 0
        
        for (meterId, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }
            
            // Berechne Gesamtverbrauch für diesen Zähler
            var consumption: Double = 0
            for i in 0..<(sorted.count - 1) {
                consumption += sorted[i + 1].value - sorted[i].value
            }
            
            consumptions.append((meterId, consumption))
            totalConsumption += consumption
        }
        
        if totalConsumption == 0 { return [] }
        
        return consumptions.compactMap { item in
            if let meter = meters.first(where: { $0.meterNumber == item.meterId }) {
                let percentage = (item.consumption / totalConsumption) * 100
                return (meter.name, percentage)
            }
            return nil
        }.sorted { $0.percentage > $1.percentage }
    }
}
