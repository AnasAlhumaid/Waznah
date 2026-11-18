//
//  Main.swift
//  Waznah
//
//  Created by Anas Hamad on 10/4/22.
//

import SwiftUI
import FirebaseCore




@main
struct WaznahApp: App {
    init(){
        FirebaseApp.configure()
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
       
        WindowGroup {
            AppLaunchView()
                .environment(\.managedObjectContext, CoreDataProvider.shared.viewContext)
                
        }
       
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        Task { @MainActor in
            WaznahDeepLinkRouter.shared.handle(url: url)
        }
        return true
    }
}

enum TimeColorSchemeKey: EnvironmentKey {
    static var defaultValue: ColorScheme { .dark }
}

extension EnvironmentValues {
    var timeColorScheme: ColorScheme {
        get { self[TimeColorSchemeKey.self] }
        set { self[TimeColorSchemeKey.self] = newValue }
    }
}

struct TimeColorSchemeModifier: ViewModifier {
    @Environment(\.timeColorScheme) private var timeColorScheme

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(timeColorScheme)
    }
}
extension View {
    func timeColorScheme(_ colorScheme: ColorScheme) -> some View {
        self
            .environment(\.timeColorScheme, colorScheme)
    }
}
