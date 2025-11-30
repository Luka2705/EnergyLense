import SwiftUI
import Charts

struct MeterComparisonView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var selectedMeterIds: Set<String> = []
    @State private var meterReadings: [String: [Reading]] = [:]
    
    private var selectedMeters: [Meter] {
        firebaseService.meters.filter { selectedMeterIds.contains($0.meterNumber) }
    }
    
    private var allReadingsForChart: [(meterId: String, meterName: String, readings: [Reading])] {
        selectedMeters.compactMap { meter in
            if let readings = meterReadings[meter.meterNumber], !readings.isEmpty {
                return (meter.meterNumber, meter.name, readings)
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    meterSelectionSection
                    
                    if selectedMeterIds.count >= 2 {
                        Divider()
                            .padding(.horizontal)
                        
                        combinedStatisticsSection
                        comparisonChartSection
                        consumptionBreakdownSection
                    } else {
                        emptyStateView
                    }
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("Compare Meters", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Meter Selection Section
    
    private var meterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(firebaseService.meters) { meter in
                meterSelectionRow(meter)
            }
        }
    }
    
    private func meterSelectionRow(_ meter: Meter) -> some View {
        Button {
            Haptics.shared.play(.light)
            if selectedMeterIds.contains(meter.meterNumber) {
                selectedMeterIds.remove(meter.meterNumber)
            } else {
                selectedMeterIds.insert(meter.meterNumber)
                loadReadings(for: meter.meterNumber)
            }
        } label: {
            HStack {
                Image(systemName: selectedMeterIds.contains(meter.meterNumber) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        selectedMeterIds.contains(meter.meterNumber) ?
                        Color.blue : Color.gray
                    )
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meter.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Meter #: \(meter.meterNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Combined Statistics Section
    
    private var combinedStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Combined Statistics", comment: ""))
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ComparisonStatCard(
                        title: NSLocalizedString("Total Consumption", comment: ""),
                        value: ComparisonStatsCalculator.calculateTotalConsumption(for: meterReadings),
                        unit: "kWh"
                    )
                    
                    ComparisonStatCard(
                        title: NSLocalizedString("Avg Daily", comment: ""),
                        value: ComparisonStatsCalculator.calculateAverageDailyConsumption(for: meterReadings),
                        unit: NSLocalizedString("kWh/day", comment: "")
                    )
                }
                
                HStack(spacing: 12) {
                    ComparisonStatCard(
                        title: NSLocalizedString("Next Month", comment: ""),
                        value: ComparisonStatsCalculator.calculateCombinedMonthlyPrediction(for: meterReadings),
                        unit: NSLocalizedString("kWh", comment: "")
                    )
                    
                    ComparisonStatCard(
                        title: NSLocalizedString("Highest User", comment: ""),
                        value: ComparisonStatsCalculator.findHighestConsumingMeter(for: meterReadings, meters: selectedMeters),
                        unit: ""
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Comparison Chart Section
    
    @ViewBuilder
    private var comparisonChartSection: some View {
        if !allReadingsForChart.isEmpty {
            ComparisonChartView(chartData: allReadingsForChart)
        }
    }
    
    // MARK: - Consumption Breakdown Section
    
    @ViewBuilder
    private var consumptionBreakdownSection: some View {
        let percentages = ComparisonStatsCalculator.calculateConsumptionPercentages(for: meterReadings, meters: selectedMeters)
        if !percentages.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Consumption Breakdown", comment: ""))
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(percentages, id: \.name) { item in
                        HStack {
                            Text(item.name)
                                .font(.headline)
                            Spacer()
                            Text("\(item.percentage, specifier: "%.1f")%")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(NSLocalizedString("Select at least 2 meters to compare", comment: ""))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Helper Methods
    
    private func loadReadings(for meterId: String) {
        firebaseService.listenToReadings(for: meterId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            meterReadings[meterId] = firebaseService.readings
        }
    }
}

// MARK: - Comparison Chart View

struct ComparisonChartView: View {
    let chartData: [(meterId: String, meterName: String, readings: [Reading])]
    
    private var flattenedData: [(meterName: String, reading: Reading)] {
        chartData.flatMap { meterData in
            meterData.readings.map { (meterData.meterName, $0) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Consumption Comparison", comment: ""))
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Chart(flattenedData, id: \.reading.id) { item in
                LineMark(
                    x: .value("Date", item.reading.date),
                    y: .value("Value", item.reading.value),
                    series: .value("Meter", item.meterName)
                )
                .foregroundStyle(by: .value("Meter", item.meterName))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", item.reading.date),
                    y: .value("Value", item.reading.value)
                )
                .foregroundStyle(by: .value("Meter", item.meterName))
            }
            .frame(height: 250)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - Comparison Stat Card

struct ComparisonStatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if unit.isEmpty {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

