//
//  XRP.swift
//  Alamofire
//
//  Created by Mitch Lang on 3/31/19.
//

import Foundation

public struct Transaction {
    public var type: String
    public var address: String
    public var amount: Int
    public var date: Date
}

public struct Account: Codable {
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

public struct Tx: Codable {
    public var TransactionType: String
    public var Account: String
    public var Destination: String
    public var Amount: String
    public var Flags: Int
    public var LastLedgerSequence: Int
    public var Fee: String
    public var Sequence: Int
    
    public init(TransactionType: String, Account: String, Destination: String, Amount: String, Flags: Int, LastLedgerSequence: Int, Fee: String, Sequence: Int){
        self.TransactionType = TransactionType
        self.Account = Account
        self.Destination = Destination
        self.Amount = Amount
        self.Flags = Flags
        self.LastLedgerSequence = LastLedgerSequence
        self.Fee = Fee
        self.Sequence = Sequence
        
    }
}
