//
//  XRPTransaction.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import FutureKit

let HASH_TX_SIGN: [UInt8] = [0x53,0x54,0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73,0x74,0x78,0x00]

public class XRPTransaction {
    
    var fields: [String: Any] = [:]
    
    public init(fields: [String:Any], autofill: Bool = false){
        self.fields = enforceJSONTypes(fields: fields)
    }

    @available(iOS 10.0, *)
    public static func send(from wallet: XRPWallet, to address: String, amount: XRPAmount) -> Future<NSDictionary> {
        
        let p = Promise<NSDictionary>()
        
        // dictionary containing partial transaction fields
        let fields: [String:Any] = [
            "TransactionType" : "Payment",
            "Destination" : address,
            "Amount" : String(amount.drops),
            "Flags" : 2147483648,
        ]

        // create the transaction from dictionary
        let partialTransaction = XRPTransaction(fields: fields)

        // autofill missing transaction fields (online)
        _ = partialTransaction.autofill(address: wallet.address).onSuccess { (transaction) -> () in
            
            // sign the transaction (offline)
            let signedTransaction = try! transaction.sign(wallet: wallet)
            
            // submit the transaction (online)
            _ = signedTransaction.submit().onSuccess { (dict) in
                p.completeWithSuccess(dict)
            }
            .onFail(block: { (error) in
                p.completeWithFail(error)
            })
        }
        .onFail(block: { (error) in
            p.completeWithFail(error)
        })
        
        return p.future
    }
    
    // autofills account address, ledger sequence, fee, and sequence
    @available(iOS 10.0, *)
    public func autofill(address: String) -> Future<XRPTransaction> {
        
        let p = Promise<XRPTransaction>()
        
        // network calls to retrive current account and ledger info
        let futureLedgerInfo = XRPLedger.currentLedgerInfo()
        _ = futureLedgerInfo.onSuccess { (ledgerInfo) -> () in
            let futureAccountInfo = XRPLedger.getAccountInfo(account: address)
            _ = futureAccountInfo.onSuccess { (accountInfo) -> () in

                // dictionary containing transaction fields
                let filledFields: [String:Any] = [
                    "Account" : accountInfo.address,
                    "LastLedgerSequence" : ledgerInfo.index+5,
                    "Fee" : "40", // FIXME: determine fee automatically
                    "Sequence" : accountInfo.sequence,
                ]
                
                self.fields = self.fields.merging(self.enforceJSONTypes(fields: filledFields)) { (_, new) in new }
                
                p.completeWithSuccess(self)
            }
            futureAccountInfo.onFail { (error) -> () in
                p.completeWithFail("Request failed.")
            }
        }
        futureLedgerInfo.onFail { (error) -> () in
            p.completeWithFail("Request failed.")
        }

        return p.future
    }
    
    public func sign(wallet: XRPWallet) throws -> XRPTransaction {
        
        // make sure all fields are compatible
        self.fields = self.enforceJSONTypes(fields: self.fields)
        
        // add account public key to fields
        self.fields["SigningPubKey"] = wallet.publicKey as AnyObject
        
        // serialize transation to binary
        let blob = XRPSerializer.sharedInstance.serializeTx(tx: self.fields, forSigning: true)
        
        // remove one byte prefix from primary key
        let privateKey = [UInt8](Data(hex: wallet.privateKey).suffix(from: 1))
        
        // add the transaction prefix to the blob
        let data: [UInt8] = HASH_TX_SIGN + blob
        
        // sign the prefixed blob
        let signature = try SECP256K1.sign(data: data, privateKey: privateKey)
        
        // verify signature
        let publicKey = [UInt8](Data(hex: wallet.publicKey))
        let verified = try SECP256K1.verify(signature: signature, data: data, publicKey: publicKey)
        if !verified {
            fatalError()
        }
        
        // create another transaction instance and add the signature to the fields
        let signedTransaction = XRPTransaction(fields: self.fields)
        signedTransaction.fields["TxnSignature"] = Data(signature).toHexString().uppercased() as Any
        return signedTransaction
    }
    
    public func submit() -> Future<NSDictionary> {
        let tx = XRPSerializer.sharedInstance.serializeTx(tx: self.fields, forSigning: false).toHexString().uppercased()
        return XRPLedger.submit(txBlob: tx)
    }
    
    public func getJSONString() -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: self.fields, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    private func enforceJSONTypes(fields: [String:Any]) -> [String:Any]{
        let jsonData = try! JSONSerialization.data(withJSONObject: fields, options: .prettyPrinted)
        let fields = try! JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
        return fields as! [String:Any]
    }
}
