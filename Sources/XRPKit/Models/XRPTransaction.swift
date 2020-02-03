//
//  XRPTransaction.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

let HASH_TX_SIGN: [UInt8] = [0x53,0x54,0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73,0x74,0x78,0x00]

public class XRPTransaction {
    
    var fields: [String: Any] = [:]
    
    public init(fields: [String:Any], autofill: Bool = false){
        self.fields = enforceJSONTypes(fields: fields)
    }

    @available(iOS 10.0, *)
    public static func send(from wallet: XRPWallet, to address: String, amount: XRPAmount, completion: @escaping ((Result<NSDictionary, Error>) -> ())) {
        
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
        _ = partialTransaction.autofill(address: wallet.address, completion: { (result) in
            switch result {
            case .success(let tx):
                // sign the transaction (offline)
                let signedTransaction = try! tx.sign(wallet: wallet)
                
                // submit the transaction (online)
                _ = signedTransaction.submit(completion: { (result) in
                    switch result {
                    case .success(let dict):
                        completion(.success(dict))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
                
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    // autofills account address, ledger sequence, fee, and sequence
    @available(iOS 10.0, *)
    public func autofill(address: String, completion: @escaping ((Result<XRPTransaction, Error>) -> ())) {

        // network calls to retrive current account and ledger info
        XRPLedger.currentLedgerInfo(completion: { (result) in
            switch result {
            case .success(let ledgerInfo):
                XRPLedger.getAccountInfo(account: address) { (result) in
                    switch result {
                    case .success(let accountInfo):
                        // dictionary containing transaction fields
                        let filledFields: [String:Any] = [
                            "Account" : accountInfo.address,
                            "LastLedgerSequence" : ledgerInfo.index+5,
                            "Fee" : "40", // FIXME: determine fee automatically
                            "Sequence" : accountInfo.sequence,
                        ]
                        self.fields = self.fields.merging(self.enforceJSONTypes(fields: filledFields)) { (_, new) in new }
                        completion(.success(self))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
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
    
    public func submit(completion: @escaping ((Result<NSDictionary, Error>) -> ()))  {
        let tx = Serializer().serializeTx(tx: self.fields, forSigning: false).toHexString().uppercased()
        return XRPLedger.submit(txBlob: tx) { (result) in
            switch result {
            case .success(let tx):
                completion(.success(tx))
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
