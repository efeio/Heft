//
//  NotificationService.swift
//  Heft
//
//  Weekly weigh-in notification scheduler using UserNotifications framework.
//

import Foundation
import UserNotifications

enum NotificationService {
    static let notificationIdentifier = "weekly-weigh-in"
    static let notificationPrefix = "heft-weigh-in"

    /// Requests authorization for alerts and sounds. Returns whether granted.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            return false
        }
    }

    /// Clears all existing weigh-in notifications.
    static func removeAllWeighInNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let idsToRemove = pending.map(\.identifier).filter {
            $0 == notificationIdentifier || $0.hasPrefix(notificationPrefix) || $0.hasPrefix("weigh-in")
        }
        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }

    /// Schedules notifications based on the user's chosen frequency (daily, weekly, or specific days).
    static func scheduleNotifications(
        frequency: WeighInFrequency,
        days: [Int],
        hour: Int,
        minute: Int,
        userName: String? = nil
    ) async {
        let center = UNUserNotificationCenter.current()

        // Always remove existing scheduled notifications first
        await removeAllWeighInNotifications()

        // Verify current authorization status
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let trimmedName = userName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        switch frequency {
        case .daily:
            let content = UNMutableNotificationContent()
            if !trimmedName.isEmpty {
                content.title = "\(trimmedName), günaydın"
                content.body = "Sabah tartınızı kaydetmeyi unutmayın. Yeni kilonuzu Heft'e ekleyin."
            } else {
                content.title = "Günaydın"
                content.body = "Sabah tartınızı kaydetmeyi unutmayın. Yeni kilonuzu Heft'e ekleyin."
            }
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "\(notificationPrefix)-daily", content: content, trigger: trigger)
            try? await center.add(request)

        case .weekly:
            let day = days.first ?? 2
            let content = UNMutableNotificationContent()
            if !trimmedName.isEmpty {
                content.title = "\(trimmedName), tartım zamanı"
                content.body = "Bugün haftalık tartım gününüz. Yeni kilonuzu Heft'e kaydedin."
            } else {
                content.title = "Tartım Zamanı"
                content.body = "Bugün haftalık tartım gününüz. Yeni kilonuzu Heft'e kaydedin."
            }
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.weekday = day
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "\(notificationPrefix)-weekly-\(day)", content: content, trigger: trigger)
            try? await center.add(request)

        case .custom:
            let targetDays = days.isEmpty ? [2] : days
            for day in targetDays {
                let content = UNMutableNotificationContent()
                if !trimmedName.isEmpty {
                    content.title = "\(trimmedName), tartım zamanı"
                    content.body = "Bugün tartım gününüz. Yeni kilonuzu Heft'e kaydedin."
                } else {
                    content.title = "Tartım Zamanı"
                    content.body = "Bugün tartım gününüz. Yeni kilonuzu Heft'e kaydedin."
                }
                content.sound = .default

                var dateComponents = DateComponents()
                dateComponents.weekday = day
                dateComponents.hour = hour
                dateComponents.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(notificationPrefix)-custom-\(day)", content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    /// Legacy convenience wrapper: schedules a repeating weekly weigh-in notification.
    static func scheduleWeeklyNotification(day: Int, hour: Int, minute: Int, userName: String? = nil) async {
        await scheduleNotifications(frequency: .weekly, days: [day], hour: hour, minute: minute, userName: userName)
    }
}

