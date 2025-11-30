import Foundation

/// Generator für realistische Stromzähler-Testdaten
struct TestDataGenerator {
    
    /// Generiert realistische Testdaten für einen Stromzähler
    /// - Parameters:
    ///   - startDate: Startdatum für die Testdaten
    ///   - endDate: Enddatum für die Testdaten
    ///   - initialReading: Initialer Zählerstand in kWh
    ///   - avgDailyConsumption: Durchschnittlicher Tagesverbrauch in kWh
    ///   - variance: Variation des Verbrauchs (0.0 - 1.0, z.B. 0.3 = ±30%)
    ///   - readingInterval: Tage zwischen Ablesungen
    /// - Returns: Array von Reading-Objekten
    static func generateReadings(
        startDate: Date = Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
        endDate: Date = Date(),
        initialReading: Double = 5000.0,
        avgDailyConsumption: Double = 15.0,
        variance: Double = 0.3,
        readingInterval: Int = 7
    ) -> [Reading] {
        
        var readings: [Reading] = []
        var currentDate = startDate
        var currentReading = initialReading
        
        while currentDate <= endDate {
            // Füge Ablesung hinzu
            let reading = Reading(
                meterId: "test-meter",
                value: currentReading,
                date: currentDate
            )
            readings.append(reading)
            
            // Berechne nächste Ablesung
            let daysUntilNext = Double(readingInterval)
            let randomFactor = 1.0 + Double.random(in: -variance...variance)
            let consumption = avgDailyConsumption * daysUntilNext * randomFactor
            
            currentReading += consumption
            currentDate = Calendar.current.date(byAdding: .day, value: readingInterval, to: currentDate)!
        }
        
        return readings
    }
    
    /// Generiert Testdaten für mehrere Stromzähler mit unterschiedlichen Verbrauchsprofilen
    static func generateMultipleMeterReadings() -> [String: [Reading]] {
        var allReadings: [String: [Reading]] = [:]
        
        // Haushalt (niedriger Verbrauch)
        let household = generateReadings(
            initialReading: 2500.0,
            avgDailyConsumption: 8.0,  // ~240 kWh/Monat
            variance: 0.25,
            readingInterval: 5
        )
        allReadings["household-001"] = household.map { reading in
            var r = reading
            r.meterId = "household-001"
            return r
        }
        
        // Büro (mittlerer Verbrauch)
        let office = generateReadings(
            initialReading: 8000.0,
            avgDailyConsumption: 25.0,  // ~750 kWh/Monat
            variance: 0.4,
            readingInterval: 7
        )
        allReadings["office-002"] = office.map { reading in
            var r = reading
            r.meterId = "office-002"
            return r
        }
        
        // Werkstatt (hoher Verbrauch)
        let workshop = generateReadings(
            initialReading: 15000.0,
            avgDailyConsumption: 45.0,  // ~1350 kWh/Monat
            variance: 0.5,
            readingInterval: 7
        )
        allReadings["workshop-003"] = workshop.map { reading in
            var r = reading
            r.meterId = "workshop-003"
            return r
        }
        
        return allReadings
    }
    
    /// Generiert saisonale Testdaten (höherer Verbrauch im Winter)
    static func generateSeasonalReadings(
        startDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
        endDate: Date = Date(),
        initialReading: Double = 10000.0,
        baseConsumption: Double = 15.0,
        readingInterval: Int = 7
    ) -> [Reading] {
        
        var readings: [Reading] = []
        var currentDate = startDate
        var currentReading = initialReading
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            let reading = Reading(
                meterId: "seasonal-meter",
                value: currentReading,
                date: currentDate
            )
            readings.append(reading)
            
            // Saisonaler Faktor (Winter = mehr Verbrauch)
            let month = calendar.component(.month, from: currentDate)
            let seasonalFactor: Double
            switch month {
            case 12, 1, 2:  // Winter
                seasonalFactor = 1.5
            case 3, 4, 11:  // Übergang
                seasonalFactor = 1.2
            case 5, 6, 7, 8, 9, 10:  // Sommer
                seasonalFactor = 0.8
            default:
                seasonalFactor = 1.0
            }
            
            let daysUntilNext = Double(readingInterval)
            let randomFactor = 1.0 + Double.random(in: -0.2...0.2)
            let consumption = baseConsumption * daysUntilNext * seasonalFactor * randomFactor
            
            currentReading += consumption
            currentDate = calendar.date(byAdding: .day, value: readingInterval, to: currentDate)!
        }
        
        return readings
    }
    
    /// Print-Funktion für einfaches Debugging
    static func printReadings(_ readings: [Reading]) {
        print("\n--- Testdaten ---")
        for reading in readings {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            print("\(dateFormatter.string(from: reading.date)): \(String(format: "%.1f", reading.value)) kWh")
        }
        
        if readings.count >= 2 {
            let first = readings.first!
            let last = readings.last!
            let days = last.date.timeIntervalSince(first.date) / 86400
            let consumption = last.value - first.value
            let avgDaily = consumption / days
            print("\nGesamtverbrauch: \(String(format: "%.1f", consumption)) kWh")
            print("Durchschnitt: \(String(format: "%.1f", avgDaily)) kWh/Tag")
        }
        print("--- Ende ---\n")
    }
}
