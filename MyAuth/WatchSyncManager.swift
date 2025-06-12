//
//  WatchSyncManager.swift
//  MyAuth
//
//  Created by Jack Rogers on 6/12/25.
//

import WatchConnectivity

class WatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchSyncManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sync(accounts: [TOTPAccount]) {
        guard WCSession.default.isPaired && WCSession.default.isWatchAppInstalled else { return }

        let payload = accounts.map {
            [
                "id": $0.id.uuidString,
                "issuer": $0.issuer,
                "accountName": $0.accountName,
                "secret": $0.secret,
                "seconds": $0.seconds
            ] as [String: Any]
        }

        WCSession.default.transferUserInfo(["accounts": payload])
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {}
}
