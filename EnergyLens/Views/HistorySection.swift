import SwiftUI

struct HistorySection: View {
    let readings: [Reading]
    let onEdit: (Reading) -> Void
    let onDelete: (Reading) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("History")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(readings) { reading in
                Button { onEdit(reading) } label: {
                    HistoryRow(reading: reading)
                }
                .padding(.horizontal)
                .contextMenu {
                    Button(role: .destructive) {
                        onDelete(reading)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let reading: Reading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(reading.value, specifier: "%.1f") kWh")
                    .bold()
                Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
