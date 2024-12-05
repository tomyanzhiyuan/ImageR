//
//  NotificationManager.swift
//  ImageR
//
//  Created by Tom Yan Zhiyuan on 01/12/2024.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager {
   static func requestPermissions() {
       UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
           if granted {
               print("Notification permissions granted")
           } else {
               print("Notification permissions denied: \(String(describing: error))")
           }
       }
   }
   
   static func scheduleNotification(title: String, body: String) {
       let content = UNMutableNotificationContent()
       content.title = title
       content.body = body
       content.sound = .default
       
       let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
       let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
       
       UNUserNotificationCenter.current().add(request)
   }
   
   static func sendGenerationCompleteNotification(imagesCount: Int = 1, prompt: String? = nil) {
       // Only send notification if app is in background
       guard UIApplication.shared.applicationState != .active else { return }
       
       let title = "Image Generation Complete"
       let body: String
       
       if imagesCount > 1 {
           body = "\(imagesCount) images have been generated"
       } else {
           if let prompt = prompt {
               body = "Your image for '\(prompt)' is ready"
           } else {
               body = "Your image has been generated"
           }
       }
       
       scheduleNotification(title: title, body: body)
   }
}
