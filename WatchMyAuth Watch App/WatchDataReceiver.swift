//
//  WatchDataReceiver.swift
//  MyAuth
//
//  Created by Jack Rogers on 6/12/25.
//

import WatchConnectivity
import SwiftData

class WatchDataReceiver: NSObject, WCSessionDelegate, ObservableObject {
    private let modelContext: ModelContext

    init(context: ModelContext) {
        self.modelContext = context
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard let accountDictionaries = userInfo["accounts"] as? [[String: Any]] else { return }

        Task { @MainActor in
            for dict in accountDictionaries {
                guard
                    let id = UUID(uuidString: dict["id"] as? String ?? ""),
                    let issuer = dict["issuer"] as? String,
                    let name = dict["accountName"] as? String,
                    let secret = dict["secret"] as? String,
                    let seconds = dict["seconds"] as? Double
                else { continue }

                // Check if it already exists
                if let existing = try? modelContext.fetch(FetchDescriptor<TOTPAccount>(predicate: #Predicate { $0.id == id })).first {
                    existing.issuer = issuer
                    existing.accountName = name
                    existing.secret = secret
                    existing.seconds = seconds
                } else {
                    let newAccount = TOTPAccount(id: id, issuer: issuer, accountName: name, secret: secret, seconds: seconds)
                    modelContext.insert(newAccount)
                }
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
