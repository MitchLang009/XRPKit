//
//  XRPDisableMaster.swift
//  AnyCodable
//
//  Created by Mitch Lang on 2/10/20.
//

import Foundation

public enum XRPAccountSetFlag: UInt32 {
    case asfDisableMaster = 4
}

public class XRPAccountSet: XRPTransaction {
    
    public init(wallet: XRPWallet, set: XRPAccountSetFlag) {
        let _fields: [String:Any] = [
            "TransactionType" : "AccountSet",
            "SetFlag" : set.rawValue
        ]
        super.init(wallet: wallet, fields: _fields)
    }
    
    public init(wallet: XRPWallet, clear: XRPAccountSetFlag) {
        let _fields: [String:Any] = [
            "TransactionType" : "AccountSet",
            "ClearFlag" : clear.rawValue
        ]
        super.init(wallet: wallet, fields: _fields)
    }

}
