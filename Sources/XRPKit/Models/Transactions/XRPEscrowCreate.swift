//
//  XRPEscrowCreate.swift
//  AnyCodable
//
//  Created by Mitch Lang on 2/4/20.
//

import Foundation

public class XRPEscrowCreate: XRPTransaction {
    
    public init(from wallet: XRPWallet, to address: XRPAddress, amount: XRPAmount, finishAfter: Date, cancelAfter: Date?, sourceTag : UInt32? = nil) {
        
        // dictionary containing partial transaction fields
        var _fields: [String:Any] = [
            "TransactionType": "EscrowCreate",
            "FinishAfter": finishAfter.timeIntervalSinceRippleEpoch,
            "Amount": String(amount.drops),
            "Destination": address.rAddress,
        ]
        
        if let cancelAfter = cancelAfter {
            assert(cancelAfter > finishAfter)
            _fields["CancelAfter"] = cancelAfter.timeIntervalSinceRippleEpoch
        }
        
        if let destinationTag = address.tag {
            _fields["DestinationTag"] = destinationTag
        }
        
        if let sourceTag = sourceTag {
            _fields["SourceTag"] = sourceTag
        }
        
        super.init(wallet: wallet, fields: _fields)
    }

}
