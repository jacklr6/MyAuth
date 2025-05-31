//
//  TOTPAuthenticator.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/18/25.
//

import SwiftData
import Foundation

@Model
class TOTPAccount: Identifiable {
    var id: UUID
    var issuer: String
    var accountName: String
    var secret: String
    var seconds: Double
    
    init(id: UUID = UUID(), issuer: String, accountName: String, secret: String, seconds: Double = 30) {
        self.id = id
        self.issuer = issuer
        self.accountName = accountName
        self.secret = secret
        self.seconds = seconds
    }
}
