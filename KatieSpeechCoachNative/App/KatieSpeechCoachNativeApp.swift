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
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
        tabBarAppearance.backgroundColor = UIColor(KatieColors.cardBackground.opacity(0.78))
        tabBarAppearance.shadowColor = UIColor.white.withAlphaComponent(0.04)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
        }
    }
}
