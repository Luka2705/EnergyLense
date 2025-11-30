import SwiftUI
import Charts

struct ChartSection: View {
    let readings: [Reading]
    
    var body: some View {
        if readings.isEmpty { return AnyView(EmptyView()) }
        
        return AnyView(
            Chart(readings) { reading in
                LineMark(
                    x: .value("Date", reading.date),
                    y: .value("Value", reading.value)
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", reading.date),
                    y: .value("Value", reading.value)
                )
            }
            .frame(height: 200)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        )
    }
}
