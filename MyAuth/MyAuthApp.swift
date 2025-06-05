//
//  MyAuthApp.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/18/25.
//

import SwiftUI

@main
struct MyAuthApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @AppStorage("isAppFocused") private var isAppFocused: Bool = true
    
    var body: some Scene {
        WindowGroup {
            AuthMainView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .modelContainer(for: TOTPAccount.self)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                print("MyAuth is active")
                isAppFocused = true
            case .inactive:
                print("MyAuth is inactive (ie: app switcher or temporary interruption)")
                isAppFocused = false
            case .background:
                print("MyAuth is in background")
                isAppFocused = false
            @unknown default:
                break
            }
        }
    }
}
