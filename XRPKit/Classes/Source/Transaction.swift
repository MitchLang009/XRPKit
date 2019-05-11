//
//  Transaction.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import FutureKit

let HASH_TX_SIGN: [UInt8] = [0x53,0x54,0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73,0x74,0x78,0x00]

public class Transaction {
    
    var fields: [String: Any] = [:]
    
    public init(fields: [String:Any]){
        self.fields = enforceJSONTypes(fields: fields)
    }
    
    public func sign(wallet: XRPWallet) throws -> Transaction {
        
        // make sure all fields are compatible
        self.fields = self.enforceJSONTypes(fields: self.fields)
        
        // add account public key to fields
        self.fields["SigningPubKey"] = wallet.publicKey as AnyObject
        
        // serialize transation to binary
        let blob = Serializer.sharedInstance.serializeTx(tx: self.fields, forSigning: true)
        
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
        let signedTransaction = Transaction(fields: self.fields)
        signedTransaction.fields["TxnSignature"] = Data(signature).toHexString().uppercased() as Any
        return signedTransaction
    }
    
    public func submit() -> Future<Bool> {
        let tx = Serializer.sharedInstance.serializeTx(tx: self.fields, forSigning: false).toHexString().uppercased()
        return XRP.Ledger.submit(txBlob: tx)
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
