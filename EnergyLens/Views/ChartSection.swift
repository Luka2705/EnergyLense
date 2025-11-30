import SwiftUI
import Charts

struct ChartSection: View {
    let readings: [Reading]
    
    var body: some View {
        if readings.isEmpty { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Consumption Trend", comment: ""))
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)
                
                Chart(readings) { reading in
                    LineMark(
                        x: .value("Date", reading.date),
                        y: .value("Value", reading.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", reading.date),
                        y: .value("Value", reading.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.3),
                                Color(red: 0.1, green: 0.8, blue: 0.9).opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", reading.date),
                        y: .value("Value", reading.value)
                    )
                    .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1.0))
                    .symbolSize(60)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel()
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                        AxisValueLabel()
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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

