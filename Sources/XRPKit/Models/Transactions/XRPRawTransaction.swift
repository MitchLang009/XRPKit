//
//  XRPRawTransaction.swift
//  AnyCodable
//
//  Created by Mitch Lang on 2/4/20.
//

import Foundation
import NIO
import BigInt

let HASH_TX_SIGN: [UInt8] = [0x53,0x54,0x58, 0x00]
let HASH_TX_MULTISIGN: [UInt8] = [0x53,0x4D,0x54,0x00]

public class XRPRawTransaction {
    
    public internal(set) var fields: [String: Any] = [:]
    
    public init(fields: [String:Any]) {
        self.fields = enforceJSONTypes(fields: fields)
    }
    
    public func sign(wallet: XRPWallet) throws -> XRPRawTransaction {
        
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
        
        // add the signature to the fields
        self.fields["TxnSignature"] = Data(signature).toHexString().uppercased() as Any
        return self
    }
    
    public func addMultiSignSignature(wallet: XRPWallet) throws -> XRPRawTransaction {
        // make sure all fields are compatible
        self.fields = self.enforceJSONTypes(fields: self.fields)
        
        // add account public key to fields
        self.fields["SigningPubKey"] = ""
        
        // serialize transation to binary
        let blob = Serializer().serializeTx(tx: self.fields, forSigning: true)
        
        // add the transaction prefix/suffix to the blob
        let data: [UInt8] = HASH_TX_MULTISIGN + blob + wallet.accountID
        
        // sign the prefixed blob
        let algorithm = XRPWallet.getSeedTypeFrom(publicKey: wallet.publicKey).algorithm
        let signature = try algorithm.sign(message: data, privateKey: [UInt8](Data(hex: wallet.privateKey)))
        
        // verify signature
        let verified = try algorithm.verify(signature: signature, message: data, publicKey: [UInt8](Data(hex: wallet.publicKey)))
        if !verified {
            fatalError()
        }
        
        // add the signature to the fields
        let signatureDictionary = NSDictionary(dictionary: [
            "Signer" : NSDictionary(dictionary: [
                "Account" : wallet.address,
                "SigningPubKey" : wallet.publicKey,
                "TxnSignature" : signature.toHexString().uppercased() as Any,
            ])
        ])
        var signers: [NSDictionary] = self.fields["Signers"] as? [NSDictionary] ?? [NSDictionary]()
        signers.append(signatureDictionary)
        signers.sort { (d1, d2) in
            let n1 = Data(base58Decoding: (d1["Signer"] as! NSDictionary)["Account"] as! String)!
            let n2 = Data(base58Decoding: (d2["Signer"] as! NSDictionary)["Account"] as! String)!
            return BigInt(n1.hexadecimal, radix: 16)! < BigInt(n2.hexadecimal, radix: 16)!
        }
        self.fields["Signers"] = signers as Any
        
        
        return self
    }
    
    public func submit() -> EventLoopFuture<NSDictionary> {
        let promise = eventGroup.next().makePromise(of: NSDictionary.self)
        let tx = Serializer().serializeTx(tx: self.fields, forSigning: false).toHexString().uppercased()
        _ = XRPLedger.submit(txBlob: tx).map { (tx) in
            promise.succeed(tx)
        }.recover { (error) in
            promise.fail(error)
        }
        return promise.futureResult
    }
    
    public func getJSONString() -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: self.fields, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8)!
    }
    
    internal func enforceJSONTypes(fields: [String:Any]) -> [String:Any]{
        let jsonData = try! JSONSerialization.data(withJSONObject: fields, options: .prettyPrinted)
        let fields = try! JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
        return fields as! [String:Any]
    }
}
