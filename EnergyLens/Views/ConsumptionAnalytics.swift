import Foundation
import FirebaseFirestore

// MARK: - Calculator (NO lookback)

enum ConsumptionAnalytics {

    // MARK: - Interval result

    struct IntervalConsumption: Identifiable {
        let id = UUID()
        let meterId: String
        let startDate: Date
        let endDate: Date
        let consumptionKWh: Double   // delta kWh in interval
        let hours: Double            // hours between readings
        let kWhPerHour: Double       // consumptionKWh / hours
    }

    // MARK: - 1) Verbrauch pro Stunde je Intervall (für alle Intervalle)

    /// Computes hourly consumption (kWh/h) per interval across ALL meters.
    /// - Readings are ALWAYS sorted by date ascending before processing.
    /// - Intervals with non-positive hours or negative delta are skipped.
    static func hourlyConsumptionPerInterval(
        for meterReadings: [String: [Reading]]
    ) -> [IntervalConsumption] {

        var results: [IntervalConsumption] = []

        for (meterId, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }

            for i in 0..<(sorted.count - 1) {
                let start = sorted[i]
                let end = sorted[i + 1]

                let hours = end.date.timeIntervalSince(start.date) / 3600.0
                guard hours > 0 else { continue }

                let delta = end.value - start.value
                guard delta >= 0 else { continue } // reset/wrong input → skip

                results.append(
                    IntervalConsumption(
                        meterId: meterId,
                        startDate: start.date,
                        endDate: end.date,
                        consumptionKWh: delta,
                        hours: hours,
                        kWhPerHour: delta / hours
                    )
                )
            }
        }

        return results.sorted { $0.startDate < $1.startDate }
    }

    // MARK: - 2) Letztes Intervall je Zähler (NUR Differenz zwischen den letzten 2 Messungen)

    /// Returns exactly ONE interval per meter: the last two readings (latest interval).
    /// This matches "immer nur die differenz zwischen den zwei messungen" (the most recent two).
    static func lastIntervalPerMeter(
        for meterReadings: [String: [Reading]]
    ) -> [IntervalConsumption] {

        var results: [IntervalConsumption] = []

        for (meterId, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }

            let start = sorted[sorted.count - 2]
            let end = sorted[sorted.count - 1]

            let hours = end.date.timeIntervalSince(start.date) / 3600.0
            guard hours > 0 else { continue }

            let delta = end.value - start.value
            guard delta >= 0 else { continue }

            results.append(
                IntervalConsumption(
                    meterId: meterId,
                    startDate: start.date,
                    endDate: end.date,
                    consumptionKWh: delta,
                    hours: hours,
                    kWhPerHour: delta / hours
                )
            )
        }

        // sort by endDate (latest first) or startDate; choose what you prefer
        return results.sorted { $0.endDate < $1.endDate }
    }

    // MARK: - 3) Durchschnittliche Stundenrate (OHNE lookback)

    /// Time-weighted average hourly consumption across ALL meters using ALL available intervals.
    /// Formula: sum(delta kWh) / sum(hours)
    static func averageHourlyConsumptionAllData(
        for meterReadings: [String: [Reading]]
    ) -> Double? {

        var totalKWh: Double = 0
        var totalHours: Double = 0

        for (_, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }

            for i in 0..<(sorted.count - 1) {
                let start = sorted[i]
                let end = sorted[i + 1]

                let hours = end.date.timeIntervalSince(start.date) / 3600.0
                guard hours > 0 else { continue }

                let delta = end.value - start.value
                guard delta >= 0 else { continue }

                totalKWh += delta
                totalHours += hours
            }
        }

        guard totalHours > 0 else { return nil }
        return totalKWh / totalHours
    }

    // MARK: - 4) Projektionen (OHNE lookback)

    /// Projection based on ALL historical data (weighted average across all intervals).
    static func projectedDailyConsumptionAllData(
        for meterReadings: [String: [Reading]]
    ) -> String {
        guard let avgHourly = averageHourlyConsumptionAllData(for: meterReadings) else { return "-" }
        return String(format: "%.1f", avgHourly * 24.0)
    }

    static func projectedYearlyConsumptionAllData(
        for meterReadings: [String: [Reading]]
    ) -> String {
        guard let avgHourly = averageHourlyConsumptionAllData(for: meterReadings) else { return "-" }
        return String(format: "%.0f", avgHourly * 8760.0)
    }

    /// Projection based ONLY on the latest interval per meter (most reactive / most noisy).
    /// If multiple meters are selected, their kWh/h are summed.
    static func projectedDailyConsumptionFromLastInterval(
        for meterReadings: [String: [Reading]]
    ) -> String {
        let intervals = lastIntervalPerMeter(for: meterReadings)
        guard !intervals.isEmpty else { return "-" }
        let hourlySum = intervals.reduce(0.0) { $0 + $1.kWhPerHour }
        return String(format: "%.1f", hourlySum * 24.0)
    }

    static func projectedYearlyConsumptionFromLastInterval(
        for meterReadings: [String: [Reading]]
    ) -> String {
        let intervals = lastIntervalPerMeter(for: meterReadings)
        guard !intervals.isEmpty else { return "-" }
        let hourlySum = intervals.reduce(0.0) { $0 + $1.kWhPerHour }
        return String(format: "%.0f", hourlySum * 8760.0)
    }

    // MARK: - 5) Optional: Gesamter Verbrauch (kWh)

    static func totalConsumptionKWh(
        for meterReadings: [String: [Reading]]
    ) -> Double {

        var total: Double = 0

        for (_, readings) in meterReadings {
            let sorted = readings.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { continue }

            for i in 0..<(sorted.count - 1) {
                let delta = sorted[i + 1].value - sorted[i].value
                if delta >= 0 { total += delta } // ignore resets
            }
        }

        return total
    }
}
