//
//  XRPStructures.swift
//  XRPKit
//
//  Created by Mitch Lang on 3/31/19.
//

import Foundation

public struct XRPTransactionHist {
    public var type: String
    public var address: String
    public var amount: XRPAmount
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

public struct XRPCurrentLedgerInfo {
    public var index: Int
    public var minFee: Int
    public var maxFee: Int
}

public struct XRPAccountInfo {
    public var address: String
    public var drops: Int
    public var sequence: Int
}
