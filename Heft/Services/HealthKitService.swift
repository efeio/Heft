//
//  HealthKitService.swift
//  Heft
//
//  Apple HealthKit integration for syncing body mass data.
//

import Foundation
import HealthKit
import SwiftUI

@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private let bodyMassType = HKQuantityType(.bodyMass)

    private let syncEnabledKey = "healthKitSyncEnabled"

    var isSyncEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: syncEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: syncEnabledKey)
        }
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private init() {}

    /// Requests authorization to read and write body mass (weight)
    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else { return false }

        let shareTypes: Set<HKSampleType> = [bodyMassType]
        let readTypes: Set<HKObjectType> = [bodyMassType]

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            return true
        } catch {
            return false
        }
    }

    /// Saves a weight record to Apple Health
    @discardableResult
    func saveWeight(weightKg: Double, date: Date) async -> Bool {
        guard isSyncEnabled && isHealthDataAvailable else { return false }

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)

        do {
            try await healthStore.save(sample)
            return true
        } catch {
            print("Failed to save sample to HealthKit: \(error)")
            return false
        }
    }

    /// Batch exports Heft weight entries to Apple Health
    func exportWeights(entries: [(date: Date, weightKg: Double)]) async -> Int {
        guard isHealthDataAvailable else { return 0 }
        let authorized = await requestAuthorization()
        guard authorized else { return 0 }

        var count = 0
        for entry in entries {
            let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: entry.weightKg)
            let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: entry.date, end: entry.date)
            do {
                try await healthStore.save(sample)
                count += 1
            } catch {
                print("Failed to export entry for \(entry.date): \(error)")
            }
        }
        return count
    }

    /// Removes body mass samples matching a specific day from HealthKit
    func deleteWeight(on date: Date) async {
        guard isSyncEnabled && isHealthDataAvailable else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let deleteQuery = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { [weak self] _, samples, _ in
                guard let self = self, let samples = samples, !samples.isEmpty else {
                    continuation.resume()
                    return
                }

                self.healthStore.delete(samples) { _, _ in
                    continuation.resume()
                }
            }

            healthStore.execute(deleteQuery)
        }
    }

    /// Fetches historical weights from Apple Health
    func fetchHistoricalWeights(startDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()) async -> [(date: Date, weightKg: Double)] {
        guard isHealthDataAvailable else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let results: [(date: Date, weightKg: Double)] = quantitySamples.map { sample in
                    let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    return (date: sample.startDate, weightKg: weight)
                }

                continuation.resume(returning: results)
            }

            healthStore.execute(query)
        }
    }
}
