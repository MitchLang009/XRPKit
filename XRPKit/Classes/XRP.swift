//
//  XRP.swift
//  Alamofire
//
//  Created by Mitch Lang on 3/31/19.
//

import Foundation
import Alamofire
import FutureKit
import CryptoSwift
import secp256k1


public class XRP {
    
    private static let url = "https://s.altnet.rippletest.net:51234"//"https://s2.ripple.com:51234"
    private static let dataURL = "https://testnet.data.api.ripple.com/v2/"//"https://data.ripple.com/v2/"
    private init() {}
    
    @available(iOS 10.0, *)
    public static func getTransactions(account: String) -> Future<[Transaction]> {
        let p = Promise<[Transaction]>()
        let url = txHistURLFor(account: account)
        Alamofire.request(url, method:.get, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let _array = JSON["transactions"] as! [NSDictionary]
                        let transactions = _array.map({ (dict) -> Transaction in
                            let tx = dict["tx"] as! NSDictionary
                            let destination = tx["Destination"] as! String
                            let source = tx["Account"] as! String
                            let amount = tx["Amount"] as! String
                            let dateString = dict["date"] as! String
                            let dateFormatter = ISO8601DateFormatter()
                            let date = dateFormatter.date(from: dateString)
                            let type = account == source ? "Sent" : "Received"
                            let address = account == source ? destination : source
                            return Transaction(type: type, address: address, amount: Int(amount)!, date: date!)
                        })
                        
                        p.completeWithSuccess(transactions.sorted(by: { (lh, rh) -> Bool in
                            lh.date > rh.date
                        }))
                    }
                }
        }
        return p.future
    }
    
    @available(iOS 10.0, *)
    public static func getBalance(account: String) -> Future<Int> {
        let p = Promise<Int>()
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : account
                ]
            ]
        ]
        Alamofire.request(url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let status = info["status"] as! String
                        if status != "error" {
                            let account = info["account_data"] as! NSDictionary
                            let balance = account["Balance"] as! String
                            p.completeWithSuccess(Int(balance)!)
                        } else {
                            let error = info["error_message"] as! String
                            p.completeWithFail(error)
                        }
                    }
                }
        }
        return p.future
    }
    
    @available(iOS 10.0, *)
    public static func getAccountInfo(account: String) -> Future<AccountInfo> {
        let p = Promise<AccountInfo>()
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : account,
                    "strict": true,
                    "ledger_index": "current",
                    "queue": true
                ]
            ]
        ]
        
        Alamofire.request(url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let status = info["status"] as! String
                        if status != "error" {
                            let account = info["account_data"] as! NSDictionary
                            let balance = account["Balance"] as! String
                            let address = account["Account"] as! String
                            let sequence = account["Sequence"] as! Int
                            p.completeWithSuccess(AccountInfo(address: address, drops: Int(balance)!, sequence: sequence))
                        } else {
                            let error = info["error_message"] as! String
                            p.completeWithFail(error)
                        }
                    }
                }
        }
        return p.future
    }
    
    public static func currentLedgerInfo() -> Future<CurrentLedgerInfo> {
        let p = Promise<CurrentLedgerInfo>()
        let parameters: [String: Any] = [
            "method" : "fee"
        ]
        // abstract this
        Alamofire.request(url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let drops = info["drops"] as! NSDictionary
                        let min = drops["minimum_fee"] as! String
                        let max = drops["median_fee"] as! String
                        let ledger = info["ledger_current_index"] as! Int
                        p.completeWithSuccess(CurrentLedgerInfo(index: ledger, minFee: Int(min)!, maxFee: Int(max)!))
                    }
                }
        }
        return p.future
    }
    
    public static func submit(txBlob: String) -> Future<Bool> {
        let p = Promise<Bool>()
        let parameters: [String: Any] = [
            "method" : "submit",
            "params": [
                [
                    "tx_blob": txBlob
                ]
            ]
            ]

        Alamofire.request(url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        p.completeWithSuccess(true)
                    }
                }
        }
        return p.future
    }
    
    private static func txHistURLFor(account: String) -> String {
        return "\(dataURL)accounts/\(account)/transactions?type=Payment&result=tesSUCCESS&limit=20"
    }
    
    public static func generateKeyPair(seed: String) throws -> KeyPairData {
        let seedData = Data(base58Decoding: seed)!
        let secretKey = [UInt8](seedData.sha256().prefix(through: 31))
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        var pubKey = secp256k1_pubkey()
        
        if secp256k1_ec_pubkey_create(ctx!, &pubKey, secretKey) == 0 {
            secp256k1_context_destroy(ctx)
            throw KeyPairError.invalidPrivateKey
        }
        
        var publicKey = [UInt8](repeating: 0, count: 33)
        var outputLen = 33
        _ = secp256k1_ec_pubkey_serialize(
            ctx!, &publicKey, &outputLen, &pubKey, UInt32(SECP256K1_EC_COMPRESSED))
        
        secp256k1_context_destroy(ctx)
        return KeyPairData(secretKeyBytes: secretKey, publicKeyBytes: publicKey)
    }
    
    public static func generateAddress(keyPair: KeyPairData) -> String {
        let accountID = Data([0x00]) + RIPEMD160.hash(message: Data(keyPair.publicKeyBytes).sha256())
        let checksum = accountID.sha256().sha256().prefix(through: 3)
        return String(base58Encoding: accountID + checksum)
        
    }
    
    public static func entropy() -> [UInt8]? {
        var bytes = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        if status == errSecSuccess { // Always test the status.
            return bytes
        }
        return nil
    }
    
    public enum KeyPairError: Error {
        case invalidPrivateKey
    }
    
    public enum SigningError: Error {
        case invalidSignature
    }
    
    public enum SeedType {
        case ed25519
        case secp256k1
    }
    
    public enum EncodeSeedError: Error {
        case invalidBufferSize
        case invalidSeedType
    }
    
    public static func encodeSeed(entropy: [UInt8], type: SeedType) throws -> String {
        if entropy.count != 16 {
            throw EncodeSeedError.invalidBufferSize
        }
        let version: [UInt8] = type == .ed25519 ? [0x01, 0xE1, 0x4B] : [0x21]
        let versionEntropy: [UInt8] = version + entropy
        let check = [UInt8](Data(versionEntropy).sha256().sha256().prefix(through: 3))
        let versionEntropyCheck: [UInt8] = versionEntropy + check
        return String(base58Encoding: Data(versionEntropyCheck), alphabet: Base58String.xrpAlphabet)
    }
    
    
    public static func sign(data: Data, privateKey: Data) throws -> Data {
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        var sig = secp256k1_ecdsa_signature()
        
        var _data = data.sha256()
        var _privateKey = privateKey
        let digestPointer: UnsafeMutablePointer<UInt8> = _data.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
        let privateKeyPointer: UnsafeMutablePointer<UInt8> = _privateKey.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
        secp256k1_ecdsa_sign(ctx!, &sig, digestPointer, privateKeyPointer, nil, nil)
    
//        msgDigest.withUnsafeBytes {(bytes: UnsafePointer<UInt8>)->Void in
//            secp256k1_ecdsa_sign(ctx!, &sig, bytes, privateKey, nil, nil)
//
//        }
//
//        var resultSign = msgDigest.withUnsafeMutableBytes { (msgDigestBytes) in
//            secp256k1_ecdsa_sign(ctx!, &sig, msgDigestBytes, privateKey, nil, nil)
//        }
//
//        if resultSign == 0 {
//            throw KeyPairError.invalidPrivateKey
//        }
        
        var input: [UInt8] {
            var tmp = sig.data
            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
        }
        var compactSig = secp256k1_ecdsa_signature()
        
        if secp256k1_ecdsa_signature_parse_compact(ctx!, &compactSig, input) == 0 {
            secp256k1_context_destroy(ctx)
            throw SigningError.invalidSignature
        }
        
        var csigArray: [UInt8] {
            var tmp = compactSig.data
            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
        }
        
        secp256k1_context_destroy(ctx)
        let retVal =  Data(csigArray)
        return retVal
    }

}

public func drops2XRP(_ value: Int) -> String {
    let drops = value%1000000
    let xrp = value/1000000
    let length = String(drops).count
    let _leadingZeros = 6 - length
    let leadingZeros: [Character] = Array(repeating: "0", count: _leadingZeros)
    let ret = String(xrp) + "." + String(leadingZeros) + String(drops)
    return ret
}

//public func getPublicKey(privateKey: PrivateKey) throws -> PublicKey {
//    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//    var pubKey = secp256k1_pubkey()
//
//    if secp256k1_ec_pubkey_create(ctx!, &pubKey, privateKey.getBytes()) == 0 {
//        secp256k1_context_destroy(ctx)
//        throw SigningError.invalidPrivateKey
//    }
//
//    var pubKeyBytes = [UInt8](repeating: 0, count: 33)
//    var outputLen = 33
//    _ = secp256k1_ec_pubkey_serialize(
//        ctx!, &pubKeyBytes, &outputLen, &pubKey, UInt32(SECP256K1_EC_COMPRESSED))
//
//    secp256k1_context_destroy(ctx)
//    return Secp256k1PublicKey(pubKey: pubKeyBytes)
//}
//
//public func newRandomPrivateKey() -> PrivateKey {
//    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//    let bytesCount = 32
//    var randomBytes: [UInt8] = [UInt8](repeating: 0, count: bytesCount)
//
//    repeat {
//        _ = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
//    } while secp256k1_ec_seckey_verify(ctx!, &randomBytes) != Int32(1)
//
//    secp256k1_context_destroy(ctx)
//    return Secp256k1PrivateKey(privKey: randomBytes)
//}
