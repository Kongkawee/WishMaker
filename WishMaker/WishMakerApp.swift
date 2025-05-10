import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification error: \(error)")
            } else {
                print("Permission granted: \(granted)")
            }
        }
        return true
    }
}

@main
struct WishMakerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var account = UserAccount()
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(account)
        }
    }
}
