//
//  ContentView.swift
//  WatchMyAuth Watch App
//
//  Created by Jack Rogers on 5/28/25.
//

import SwiftUI

struct WatchMainView: View {
    @State private var accountLabels: [String] = []
    @State private var totpCodes: [String] = []

    var body: some View {
        List {
            ForEach(Array(zip(accountLabels, totpCodes)), id: \.0) { label, code in
                VStack(alignment: .leading) {
                    Text(label).font(.headline)
                    Text(code).monospacedDigit().font(.title2)
                }
            }
        }
        .onAppear(perform: loadAccounts)
    }

    func loadAccounts() {
        // If you store account labels in UserDefaults or a shared file,
        // load them here. For example:
        let labels = UserDefaults.standard.stringArray(forKey: "SavedAccountLabels") ?? []

        self.accountLabels = labels
        self.totpCodes = labels.map { label in
            if let secret = KeychainHelper.read(forKey: label) {
                return TOTPGenerator.generate(secretBase32: secret) ?? "------"
            }
            return "------"
        }
    }
}

#Preview {
    WatchMainView()
}
