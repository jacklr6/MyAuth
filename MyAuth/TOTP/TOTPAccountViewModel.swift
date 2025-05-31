//
//  TOTPAccountViewModel.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/21/25.
//

import Foundation
import Combine

@MainActor
class TOTPAccountViewModel: ObservableObject, @preconcurrency Identifiable {
    let account: TOTPAccount
    private var timer: Timer?

    @Published var code: String = ""
    @Published var timeRemaining: Int = 0

    var id: String { account.id.uuidString }

    init(account: TOTPAccount) {
        self.account = account
        startTimer()
    }

    private func startTimer() {
        updateCodeAndTime()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCodeAndTime()
            }
        }
    }

    private func updateCodeAndTime() {
        let interval = Int(account.seconds)
        let now = Date()
        let secondsSinceEpoch = Int(now.timeIntervalSince1970)
        let remaining = interval - (secondsSinceEpoch % interval)

        code = TOTPGenerator.generate(secretBase32: account.secret, for: now, timeStep: interval) ?? "Invalid"
        timeRemaining = remaining
    }

    deinit {
        timer?.invalidate()
    }
}
