//
//  XRPEscrowCreate.swift
//  AnyCodable
//
//  Created by Mitch Lang on 2/4/20.
//

import Foundation

public class XRPEscrowCreate: XRPTransaction {
    
    public init(from wallet: XRPWallet, to address: String, amount: XRPAmount, finishAfter: Date, cancelAfter: Date?) {
        
        // dictionary containing partial transaction fields
        var _fields: [String:Any] = [
            "TransactionType": "EscrowCreate",
            "FinishAfter": finishAfter.timeIntervalSinceRippleEpoch,
            "Amount": String(amount.drops),
            "Destination": address,
        ]
        
        if let cancelAfter = cancelAfter {
            assert(cancelAfter > finishAfter)
            _fields["CancelAfter"] = cancelAfter.timeIntervalSinceRippleEpoch
        }
        
        super.init(wallet: wallet, fields: _fields)
    }

}
