//
//  XRPTransaction.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import NIO

let HASH_TX_SIGN: [UInt8] = [0x53,0x54,0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73,0x74,0x78,0x00]

public class XRPTransaction {
    
    var fields: [String: Any] = [:]
    
    public init(fields: [String:Any], autofill: Bool = false){
        self.fields = enforceJSONTypes(fields: fields)
    }

    @available(iOS 10.0, *)
    public static func send(from wallet: XRPWallet, to address: String, amount: XRPAmount) -> EventLoopFuture<NSDictionary> {
        
        let promise = eventGroup.next().newPromise(of: NSDictionary.self)
        
        // dictionary containing partial transaction fields
        let fields: [String:Any] = [
            "TransactionType" : "Payment",
            "Destination" : address,
            "Amount" : String(amount.drops),
            "Flags" : UInt64(2147483648),
        ]

        // create the transaction from dictionary
        let partialTransaction = XRPTransaction(fields: fields)

        // autofill missing transaction fields (online)
        _ = partialTransaction.autofill(address: wallet.address).map { (tx) in
            // sign the transaction (offline)
            let signedTransaction = try! tx.sign(wallet: wallet)
            
            // submit the transaction (online)
            _ = signedTransaction.submit().map { (dict) in
                promise.succeed(result: dict)
            }.mapIfError { (error) in
                promise.fail(error: error)
            }
        }.mapIfError { (error) in
            promise.fail(error: error)
        }
        return promise.futureResult
    }
    
    // autofills account address, ledger sequence, fee, and sequence
    @available(iOS 10.0, *)
    public func autofill(address: String) -> EventLoopFuture<XRPTransaction> {
        let promis = eventGroup.next().newPromise(of: XRPTransaction.self)
        // network calls to retrive current account and ledger info
        _ = XRPLedger.currentLedgerInfo().map { (ledgerInfo) in
            _ = XRPLedger.getAccountInfo(account: address).map { (accountInfo) in
                // dictionary containing transaction fields
                let filledFields: [String:Any] = [
                    "Account" : accountInfo.address,
                    "LastLedgerSequence" : ledgerInfo.index+5,
                    "Fee" : "40", // FIXME: determine fee automatically
                    "Sequence" : accountInfo.sequence,
                ]
                self.fields = self.fields.merging(self.enforceJSONTypes(fields: filledFields)) { (_, new) in new }
                promis.succeed(result: self)
            }.mapIfError { (error) in
                promis.fail(error: error)
            }
        }.mapIfError { (error) in
            promis.fail(error: error)
        }
        return promis.futureResult
    }
    
    
    
    public func sign(wallet: XRPWallet) throws -> XRPTransaction {
        
        // make sure all fields are compatible
        self.fields = self.enforceJSONTypes(fields: self.fields)
        
        // add account public key to fields
        self.fields["SigningPubKey"] = wallet.publicKey as AnyObject
        
        // serialize transation to binary
        let blob = Serializer().serializeTx(tx: self.fields, forSigning: true)
        
        // add the transaction prefix to the blob
        let data: [UInt8] = HASH_TX_SIGN + blob
        
        // sign the prefixed blob
        let algorithm = XRPWallet.getSeedTypeFrom(publicKey: wallet.publicKey).algorithm
        let signature = try algorithm.sign(message: data, privateKey: [UInt8](Data(hex: wallet.privateKey)))
        
        // verify signature
        let verified = try algorithm.verify(signature: signature, message: data, publicKey: [UInt8](Data(hex: wallet.publicKey)))
        if !verified {
            fatalError()
        }
        
        // create another transaction instance and add the signature to the fields
        let signedTransaction = XRPTransaction(fields: self.fields)
        signedTransaction.fields["TxnSignature"] = Data(signature).toHexString().uppercased() as Any
        return signedTransaction
    }
    
    public func submit() -> EventLoopFuture<NSDictionary> {
        let promise = eventGroup.next().newPromise(of: NSDictionary.self)
        let tx = Serializer().serializeTx(tx: self.fields, forSigning: false).toHexString().uppercased()
        _ = XRPLedger.submit(txBlob: tx).map { (dict) in
            promise.succeed(result: dict)
        }.mapIfError { (error) in
            promise.fail(error: error)
        }
        return promise.futureResult
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
