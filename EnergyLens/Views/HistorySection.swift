import SwiftUI

struct HistorySection: View {
    let readings: [Reading]
    let onEdit: (Reading) -> Void
    let onDelete: (Reading) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("History", comment: ""))
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if readings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("No readings yet", comment: ""))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("Add your first reading to start tracking", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(readings.enumerated()), id: \.element.id) { index, reading in
                        Button {
                            Haptics.shared.play(.light)
                            onEdit(reading)
                        } label: {
                            HistoryRow(
                                reading: reading,
                                previousReading: index < readings.count - 1 ? readings[index + 1] : nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button(role: .destructive) {
                                onDelete(reading)
                            } label: {
                                Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Haptics.shared.play(.light)
                                onDelete(reading)
                            } label: {
                                Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                            }
                        }
                        
                        if index < readings.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
            }
        }
    }
}

struct HistoryRow: View {
    let reading: Reading
    let previousReading: Reading?
    
    private var consumptionChange: Double? {
        guard let previous = previousReading else { return nil }
        return reading.value - previous.value
    }
    
    private var daysSincePrevious: Double? {
        guard let previous = previousReading else { return nil }
        return reading.date.timeIntervalSince(previous.date) / 86400
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "bolt.fill")
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String(format: NSLocalizedString("%@ kWh", comment: ""), String(format: "%.1f", reading.value)))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let change = consumptionChange, let days = daysSincePrevious, days > 0 {
                        let dailyRate = change / days
                        HStack(spacing: 3) {
                            Image(systemName: dailyRate > 0 ? "arrow.up.forward" : "arrow.down.forward")
                                .font(.system(size: 10))
                            Text("\(abs(dailyRate), specifier: "%.1f")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(dailyRate > 0 ? .orange : .green)
                    }
                }
                
                Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
