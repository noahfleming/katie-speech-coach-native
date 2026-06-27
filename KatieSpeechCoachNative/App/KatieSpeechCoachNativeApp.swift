import SwiftUI
import UserNotifications
import UIKit

extension Notification.Name {
    static let katieReminderTapped = Notification.Name("katieReminderTapped")
}

final class KatieNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let scenarioID = response.notification.request.content.userInfo["scenarioID"] as? String
        var userInfo: [String: Any] = [:]
        if let scenarioID {
            userInfo["scenarioID"] = scenarioID
        }

        Task { @MainActor in
            NotificationCenter.default.post(
                name: .katieReminderTapped,
                object: nil,
                userInfo: userInfo.isEmpty ? nil : userInfo
            )
            completionHandler()
        }
    }
}

@main
struct KatieSpeechCoachNativeApp: App {
    @UIApplicationDelegateAdaptor(KatieNotificationDelegate.self) private var appDelegate
    @StateObject private var appViewModel = AppViewModel()

    init() {
        // KAT-283 audit: disable iOS 26's Liquid Glass floating tab bar.
        // Default behavior: tab bar floats in the middle of the screen at
        // ~80% width with empty space below (Liquid Glass aesthetic).
        // For Katie we want the traditional full-width bottom tab bar so
        // the screen feels filled and content layout is predictable.
        // See: stackoverflow.com/questions/79876945 (disableLiquidGlass pattern).
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundEffect = nil
        tabBarAppearance.backgroundColor = UIColor(KatieColors.cardBackground.opacity(0.92))
        tabBarAppearance.shadowColor = UIColor.white.withAlphaComponent(0.06)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().backgroundImage = UIImage()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
        }
    }
}
