import SwiftUI
import Charts

struct ChartSection: View {
    let readings: [Reading]
    
    @State private var currentX: Date? = nil
    @State private var tooltip: (date: Date, text: String)? = nil
    
    private var intervals: [ConsumptionAnalytics.IntervalConsumption] {
        let sorted = readings.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return [] }
        var result: [ConsumptionAnalytics.IntervalConsumption] = []
        for i in 0..<(sorted.count - 1) {
            let start = sorted[i]
            let end = sorted[i + 1]
            let hours = end.date.timeIntervalSince(start.date) / 3600.0
            guard hours > 0 else { continue }
            let delta = end.value - start.value
            guard delta >= 0 else { continue }
            let interval = ConsumptionAnalytics.IntervalConsumption(
                meterId: start.meterId,
                startDate: start.date,
                endDate: end.date,
                consumptionKWh: delta,
                hours: hours,
                kWhPerHour: delta / hours
            )
            result.append(interval)
        }
        return result
    }
    
    private struct StepPoint: Identifiable {
        let id = UUID()
        let x: Date
        let yKWhPerDay: Double
    }

    private var stepPoints: [StepPoint] {
        var points: [StepPoint] = []
        for interval in intervals {
            let yPerDay = interval.kWhPerHour * 24.0
            points.append(StepPoint(x: interval.startDate, yKWhPerDay: yPerDay))
            points.append(StepPoint(x: interval.endDate, yKWhPerDay: yPerDay))
        }
        return points
    }
    
    private var averageLine: (start: Date, end: Date, yKWhPerDay: Double)? {
        let sorted = readings.sorted { $0.date < $1.date }
        guard let oldest = sorted.first, let youngest = sorted.last, sorted.count >= 2 else { return nil }
        let hours = youngest.date.timeIntervalSince(oldest.date) / 3600.0
        guard hours > 0 else { return nil }
        let delta = youngest.value - oldest.value
        guard delta >= 0 else { return nil }
        let kwhPerDay = (delta / hours) * 24.0
        return (start: oldest.date, end: youngest.date, yKWhPerDay: kwhPerDay)
    }
    
    var body: some View {
        if intervals.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Consumption Rate (Step)", comment: ""))
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                Chart(stepPoints) { p in
                    LineMark(
                        x: .value("Date", p.x),
                        y: .value("kWh/day", p.yKWhPerDay)
                    )
                    .interpolationMethod(.stepStart)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .accessibilityLabel(Text("Date: \(p.x.formatted(date: .abbreviated, time: .shortened))"))
                    .accessibilityValue(Text(String(format: "%.2f kWh/day", p.yKWhPerDay)))

                    if let avg = averageLine {
                        RuleMark(y: .value("kWh/day", avg.yKWhPerDay))
                            .foregroundStyle(Color.red)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    
                    if let currentX {
                        RuleMark(x: .value("Selected X", currentX))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [2]))
                            .foregroundStyle(.red)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        
                        Rectangle().fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let location = value.location
                                        if let xDate: Date = proxy.value(atX: location.x) {
                                            // Snap to interval midpoint and show only average for the interval
                                            if let interval = intervals.first(where: { xDate >= $0.startDate && xDate <= $0.endDate }) {
                                                let midTime = interval.startDate.timeIntervalSince1970 + (interval.endDate.timeIntervalSince1970 - interval.startDate.timeIntervalSince1970)/2.0
                                                let mid = Date(timeIntervalSince1970: midTime)
                                                currentX = mid
                                                let kwhPerDayInt = Int((interval.kWhPerHour * 24.0).rounded())
                                                tooltip = (date: mid, text: "\(kwhPerDayInt) kWh")
                                            } else {
                                                tooltip = nil
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        tooltip = nil
                                        currentX = nil
                                    }
                            )
                            .overlay {
                                if let tip = tooltip, let xPos = proxy.position(forX: tip.date) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(tip.text.components(separatedBy: "\n"), id: \.self) { line in
                                            Text(line)
                                                .font(.caption2)
                                                .monospacedDigit()
                                        }
                                    }
                                    .padding(6)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .position(x: xPos + 8, y: 12) // near the top, slightly right of the red line
                                }
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                        AxisTick()
                        AxisValueLabel() {
                            if let y = value.as(Double.self) {
                                Text(String(format: "%.0f", y))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxisLabel(position: .leading, alignment: .center) {
                    Text("kWh/day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 220)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
        )
    }
}

