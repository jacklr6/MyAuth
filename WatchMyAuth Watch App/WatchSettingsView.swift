//
//  SwiftUIView.swift
//  WatchMyAuth Watch App
//
//  Created by Jack Rogers on 6/3/25.
//

import SwiftUI
import SwiftData

struct WatchSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [TOTPAccount]
    
    @AppStorage("showCountdown") private var showCountdown: Bool = true
    @State private var showDeleteWarning: Bool = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Visuals"), footer: Text("Change the appearance of the app.")) {
                        Toggle("Show Countdown", isOn: $showCountdown)
                        
                        Button(action: {
                            showDeleteWarning = true
                        }) {
                            HStack {
                                Text("Delete All Accounts")
                                Spacer()
                                Image(systemName: "trash")
                            }
                        }
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                    }
                    
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Text("MyAuth for watchOS")
                                Text("\(appVersion) Beta")
                                    .fontWeight(.bold)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                Text("Jack Rogers | 2025")
                            }
                            .font(.footnote)
                            Spacer()
                        }
                    }
                    .listItemTint(Color.clear)
                    .ignoresSafeArea(.all)
                }
            }
            .navigationTitle(Text("Settings"))
            .alert(isPresented: $showDeleteWarning) {
                Alert(title: Text("Are you sure?"),
                      message: Text("Deleting all accounts will remove all saved accounts and settings."),
                      primaryButton: .destructive(Text("Delete")) { deleteAllAccounts() },
                      secondaryButton: .cancel() { showDeleteWarning = false }
                )
            }
        }
    }
    
    private func deleteAllAccounts() {
        for account in accounts {
            KeychainHelper.delete(forKey: account.secret)
            context.delete(account)
        }
    }
}

#Preview {
    WatchSettingsView()
}
