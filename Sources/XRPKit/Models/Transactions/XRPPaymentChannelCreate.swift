//
//  XRPPaymentChannelCreate.swift
//  AnyCodable
//
//  Created by Denis Angell on 2/19/20.
//

import Foundation

public class XRPPaymentChannelCreate: XRPTransaction {
    
    public init(from wallet: XRPWallet, to address: XRPAddress, amount: XRPAmount, settleDelay: Date, cancelAfter: Date?, sourceTag : UInt32? = nil) {
        
        // dictionary containing partial transaction fields
        var _fields: [String:Any] = [
            "TransactionType": "PaymentChannelCreate",
            "SettleDelay": settleDelay.timeIntervalSinceRippleEpoch,
            "PublicKey": wallet.publicKey,
            "Amount": String(amount.drops),
            "Destination": address.rAddress,
        ]
        
        if let cancelAfter = cancelAfter {
            assert(cancelAfter > settleDelay)
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
