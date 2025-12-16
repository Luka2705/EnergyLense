// SeedReadingsHelper.swift
// A small helper to purge and seed readings for a given meter in Firebase.
// This is designed to be callable from anywhere in the app (or a debug entry point),
// but it keeps logic isolated from UI.

import Foundation
import Combine

// NOTE: This helper assumes the existence of the following types in your project:
// - FirebaseService.shared with methods:
//     - func listenToReadings(for meterId: String)
//     - func deleteReading(_ reading: Reading) throws
//     - func addReading(_ reading: Reading) throws
// - Reading struct with init(meterId:value:date:) and properties id, meterId, value, date.
// If your APIs differ, adjust the calls accordingly.

enum SeedError: Error {
    case missingFirebaseService
}

struct SeedReadingsHelper {
    /// Deletes all readings for the given meter and inserts the provided seed readings.
    /// - Parameters:
    ///   - meterId: The meter number/id to operate on.
    ///   - completion: Completion with a result indicating success or failure.
    static func runSeeding(meterId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Fetch current readings via FirebaseService's shared readings property.
        // We assume elsewhere in the app someone has called listenToReadings(for:),
        // but to be safe we call it here as well and then proceed after a small delay.
        FirebaseService.shared.listenToReadings(for: meterId)

        // We perform on a background queue to avoid blocking UI if called from UI.
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            // Snapshot current readings filtered by meterId.
            let current = FirebaseService.shared.readings.filter { $0.meterId == meterId }

            // 1) Delete all existing readings for this meter
            for reading in current {
                do {
                    try FirebaseService.shared.deleteReading(reading)
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }
            }

            // 2) Prepare seed data
            // Provided values:
            // 21.12.24 8:24    33400,00 KWh
            // 30.4.25 17:54    34482,00 KWh
            // 24.6.25 9:30     34894,00 KWh
            // 30.11.25 9:49    36080,00 KWh
            // 16.12.25 9:24    36210,00 KWh

            let df = DateFormatter()
            df.locale = Locale(identifier: "de_DE")
            df.timeZone = TimeZone(secondsFromGMT: 0) // adjust if your data is local time
            df.dateFormat = "d.M.yy H:mm" // matches inputs like 30.4.25 17:54

            struct SeedItem { let dateString: String; let valueString: String }
            let seeds: [SeedItem] = [
                .init(dateString: "21.12.24 8:24", valueString: "33400,00"),
                .init(dateString: "30.4.25 17:54", valueString: "34482,00"),
                .init(dateString: "24.6.25 9:30", valueString: "34894,00"),
                .init(dateString: "30.11.25 9:49", valueString: "36080,00"),
                .init(dateString: "16.12.25 9:24", valueString: "36210,00")
            ]

            for seed in seeds {
                guard let date = df.date(from: seed.dateString) else {
                    DispatchQueue.main.async { completion(.failure(NSError(domain: "SeedReadingsHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ungültiges Datum: \(seed.dateString)"]))) }
                    return
                }
                // Convert German decimal comma to dot
                let normalized = seed.valueString.replacingOccurrences(of: ",", with: ".")
                guard let value = Double(normalized) else {
                    DispatchQueue.main.async { completion(.failure(NSError(domain: "SeedReadingsHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ungültiger Wert: \(seed.valueString)"]))) }
                    return
                }

                let reading = Reading(meterId: meterId, value: value, date: date)
                do {
                    try FirebaseService.shared.addReading(reading)
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }
            }

            DispatchQueue.main.async { completion(.success(())) }
        }
    }
}

#if DEBUG
import SwiftUI

/// Optional debug entry point you can temporarily call from a view or AppDelegate.
struct SeedReadingsDebugView: View {
    @State private var status: String = "Bereit"
    @State private var meterId: String = "" // set your meter number here

    var body: some View {
        VStack(spacing: 16) {
            TextField("Meternummer", text: $meterId)
                .textFieldStyle(.roundedBorder)
            Button("Seed ausführen") {
                status = "Läuft…"
                SeedReadingsHelper.runSeeding(meterId: meterId) { result in
                    switch result {
                    case .success:
                        status = "Fertig"
                    case .failure(let error):
                        status = "Fehler: \(error.localizedDescription)"
                    }
                }
            }
            Text(status)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    SeedReadingsDebugView()
}
#endif
