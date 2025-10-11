import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set notification center delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // Explicitly register for remote notifications
    // This triggers APNS token generation
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // This method will be called when APNs has assigned the device a token
  override func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅ APNs device token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    // Firebase Messaging will automatically pick this up and trigger onTokenRefresh
  }
  
  // This method will be called if APNs fails to register
  override func application(_ application: UIApplication,
                   didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error)")
  }
}
