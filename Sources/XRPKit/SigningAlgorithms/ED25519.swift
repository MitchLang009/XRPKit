//
//  ED25519.swift
//
//  Created by Mitch Lang on 10/24/19.
//

import Foundation

class ED25519: SigningAlgorithm {
    
    static func deriveKeyPair(seed: [UInt8]) throws -> XRPKeyPair {
        let privateKey = [UInt8](Data(seed).sha512().prefix(32))
        let publicKey = Ed25519.calcPublicKey(secretKey: privateKey)
        return XRPKeyPair(privateKey: privateKey.toHexString(), publicKey: publicKey.toHexString())
    }
    
    static func sign(message: [UInt8], privateKey: [UInt8]) throws -> [UInt8] {
        return Ed25519.sign(message: message, secretKey: privateKey)
    }
    
    static func verify(signature: [UInt8], message: [UInt8], publicKey: [UInt8]) throws -> Bool {
        // remove 1 byte prefix from public key
        let publicKey = [UInt8](publicKey.suffix(from: 1))
        return Ed25519.verify(signature: signature, message: message, publicKey: publicKey)
    }
    
}
