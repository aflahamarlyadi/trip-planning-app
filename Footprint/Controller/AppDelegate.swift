//
//  AppDelegate.swift
//  Footprint
//
//  Created by Aflah Amarlyadi on 24/4/2024.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var databaseController: DatabaseProtocol?
    static let NOTIFICATION_IDENTIFIER = "edu.monash.footprint"
    var notificationsEnabled = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        databaseController = CoreDataController()
        
        // Request notification permissions
        Task {
            let notificationCenter = UNUserNotificationCenter.current()
            let notificationSettings = await notificationCenter.notificationSettings()
            if notificationSettings.authorizationStatus == .notDetermined {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert])
                self.notificationsEnabled = granted
            }
            else if notificationSettings.authorizationStatus == .authorized {
                self.notificationsEnabled = true
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        // Schedule notifications for trips starting tomorrow
        scheduleNotificationsForTomorrowPlans()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: UNUserNotificationCenterDelegate methods

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("Notification received: \(response.notification.request.content.body)")
    }
    
    // Schedule notifications for trips starting tomorrow
    private func scheduleNotificationsForTomorrowPlans() {
        guard let databaseController = databaseController else { return }
        let plans = databaseController.fetchAllPlans()  // Ensure you have a method to fetch all plans
        
        let notificationCenter = UNUserNotificationCenter.current()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        
        for plan in plans {
            guard let startDate = plan.start else { continue }
            if Calendar.current.isDate(startDate, inSameDayAs: tomorrow!) {
                let content = UNMutableNotificationContent()
                content.title = "Upcoming Trip"
                content.body = "Your trip '\(plan.name!)' starts tomorrow."
                content.sound = UNNotificationSound.default
                
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                dateComponents.hour = 18  // Set the notification time to 6 PM
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                let request = UNNotificationRequest(identifier: AppDelegate.NOTIFICATION_IDENTIFIER, content: content, trigger: trigger)
                
                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

}

