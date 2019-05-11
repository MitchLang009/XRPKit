//
//  XRP.swift
//  Alamofire
//
//  Created by Mitch Lang on 3/31/19.
//

import Foundation

public struct TransactionHist {
    public var type: String
    public var address: String
    public var amount: Int
    public var date: Date
}

public struct XRPAccount: Codable {
    public var address: String
    public var secret: String
    
    public init(address: String, secret: String) {
        self.address = address
        self.secret = secret
    }
}

public struct KeyPairData {
    public var secretKeyBytes: [UInt8]
    public var publicKeyBytes: [UInt8]
    
    public init(secretKeyBytes: [UInt8], publicKeyBytes: [UInt8]) {
        self.secretKeyBytes = secretKeyBytes
        self.publicKeyBytes = publicKeyBytes
    }
}

public struct CurrentLedgerInfo {
    public var index: Int
    public var minFee: Int
    public var maxFee: Int
}

public struct AccountInfo {
    public var address: String
    public var drops: Int
    public var sequence: Int
}

public struct XRPWallet {
    public var privateKey: String
    public var publicKey: String
    public var seed: String
    public var account: String
}
