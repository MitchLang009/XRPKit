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
