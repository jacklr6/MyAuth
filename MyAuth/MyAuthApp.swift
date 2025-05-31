//
//  MyAuthApp.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/18/25.
//

import SwiftUI

@main
struct MyAuthApp: App {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some Scene {
        WindowGroup {
            AuthMainView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .modelContainer(for: TOTPAccount.self)
        }
    }
}
