//
//  XRPPaymentChannelClaim.swift
//  AnyCodable
//
//  Created by Denis Angell on 2/19/20.
//

import Foundation

public class XRPPaymentChannelClaim: XRPTransaction {
    
    public init(from wallet: XRPWallet, to address: XRPAddress, amount: XRPAmount, channel: String, publicKey: String, signature: String, sourceTag : UInt32? = nil) {
        
        // dictionary containing partial transaction fields
        var _fields: [String:Any] = [
            "TransactionType": "PaymentChannelClaim",
            "Channel": channel,
            "Balance": String(amount.drops),
            "Amount": String(amount.drops),
            "PublicKey": publicKey,
            "Signature": signature,
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
