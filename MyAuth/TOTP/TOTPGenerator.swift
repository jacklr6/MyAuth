//
//  TOTPGenerator.swift
//  MyAuth
//
//  Created by Jack Rogers on 5/18/25.
//

import Foundation
import SwiftData
import CryptoKit
import SwiftUI

struct TOTPGenerator {
    static func generate(secretBase32: String, for date: Date = Date(), timeStep: Int = 30) -> String? {
        guard let key = base32DecodeToData(secretBase32) else { return nil }
        let counter = UInt64(date.timeIntervalSince1970) / UInt64(timeStep)
        let counterData = counterToData(counter)
        let hash = hmacSHA1(key: key, counter: counterData)
        let code = truncate(hash)
        return String(format: "%06d", code)
    }
    
    private static func base32DecodeToData(_ base32String: String) -> Data? {
        let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bits = ""
        let cleaned = base32String.uppercased().replacingOccurrences(of: "=", with: "")
        
        for character in cleaned {
            guard let index = base32Alphabet.firstIndex(of: character) else { return nil }
            let val = base32Alphabet.distance(from: base32Alphabet.startIndex, to: index)
            let binary = String(val, radix: 2).leftPadded(to: 5)
            bits += binary
        }
        
        var data = Data()
        var i = bits.startIndex
        while i < bits.endIndex {
            let nextIndex = bits.index(i, offsetBy: 8, limitedBy: bits.endIndex) ?? bits.endIndex
            let byteBits = String(bits[i..<nextIndex])
            if let byte = UInt8(byteBits.leftPadded(to: 8), radix: 2) {
                data.append(byte)
            }
            i = nextIndex
        }
        
        return data
    }

    private static func counterToData(_ counter: UInt64) -> Data {
        var bigEndian = counter.bigEndian
        return Data(bytes: &bigEndian, count: MemoryLayout.size(ofValue: bigEndian))
    }

    private static func hmacSHA1(key: Data, counter: Data) -> Data {
        let keySymmetric = SymmetricKey(data: key)
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: counter, using: keySymmetric)
        return Data(hmac)
    }

    private static func truncate(_ hash: Data) -> Int {
        let offset = Int(hash.last! & 0x0f)
        guard offset + 4 <= hash.count else { return 0 }
        
        let truncated = hash.subdata(in: offset..<offset + 4)
        
        var number: UInt32 = 0
        truncated.withUnsafeBytes {
            number = $0.load(as: UInt32.self)
        }
        
        number = UInt32(bigEndian: number) & 0x7fffffff
        return Int(number % 1_000_000)
    }
}

extension String {
    func leftPadded(to length: Int) -> String {
        String(repeating: "0", count: max(0, length - self.count)) + self
    }
}
