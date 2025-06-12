//
//  ContentView.swift
//  WatchMyAuth Watch App
//
//  Created by Jack Rogers on 5/31/25.
//

import SwiftUI
import SwiftData

struct AuthMainViewWatch: View {
    @Environment(\.modelContext) var modelContext
    @Query private var accounts: [TOTPAccount]
    @State private var showSettings: Bool = false

    var body: some View {
        let _ = WatchDataReceiver(context: modelContext)
        
        NavigationStack {
            VStack {
                if accounts.isEmpty {
                    VStack {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 72))
                        Text("No Accounts Found!")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Add an account in the MyAuth iPhone App.")
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        ForEach(accounts.map { TOTPAccountViewModel(account: $0) }, id: \.id) { viewModel in
                            TOTPRowView(viewModel: viewModel)
                        }
                        
                        Section {
                            Button(action: {
                                showSettings = true
                            }) {
                                Label("Settings", systemImage: "gear")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("MyAuth")
        }
        .sheet(isPresented: $showSettings) {
            WatchSettingsView()
        }
    }
}

#Preview {
    AuthMainViewWatch()
        .modelContainer(previewContainer1)
}

let previewContainer1: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TOTPAccount.self, configurations: config)
    
    Task { @MainActor in
        let sampleData = [
            TOTPAccount(issuer: "GitHub", accountName: "user@example.com", secret: "JBSWY3DPEHPK3PXP", seconds: 30),
            TOTPAccount(issuer: "Google", accountName: "user@gmail.com", secret: "JBSWY3DPEHPK3PXP", seconds: 30),
            TOTPAccount(issuer: "Apple", accountName: "user@icloud.com", secret: "JBSWY3DPEHPK3PXP", seconds: 30)
        ]
        for account in sampleData {
            container.mainContext.insert(account)
        }
    }

    return container
}()
