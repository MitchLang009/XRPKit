//
//  XRPPaymentTransaction.swift
//  AnyCodable
//
//  Created by Mitch Lang on 2/4/20.
//

import Foundation

public class XRPPayment: XRPTransaction {
    
    public init(from wallet: XRPWallet, to address: XRPAddress, amount: XRPAmount, sourceTag : UInt32? = nil) {
        var _fields: [String:Any] = [
            "TransactionType" : "Payment",
            "Destination" : address.rAddress,
            "Amount" : String(amount.drops),
            "Flags" : UInt64(2147483648),
        ]
        
        if let destinationTag = address.tag {
            _fields["DestinationTag"] = destinationTag
        }
        
        if let sourceTag = sourceTag {
            _fields["SourceTag"] = sourceTag
        }
        
        super.init(wallet: wallet, fields: _fields)
    }

}
