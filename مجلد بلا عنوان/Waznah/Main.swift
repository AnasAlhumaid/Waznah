//
//  Main.swift
//  Waznah
//
//  Created by Anas Hamad on 10/4/22.
//

import SwiftUI



@main
struct WaznahApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var pomodoroModel: PomodoroModel = .init()
    // MARK: Scene Phase
    @Environment(\.scenePhase) var phase
    // MARK: Storing Last Time Stamp
    @State var lastActiveTimeStamp: Date = Date()
    
    var body: some Scene {
       
        WindowGroup {
//            ContantView()
//                .environmentObject(pomodoroModel)
            ContantView()
                .environment(\.managedObjectContext, CoreDataProvider.shared.viewContext)
                
        }
       
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print(">> your code here !!")
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
func getCurrentTime() -> Date {
    return Date()
}
