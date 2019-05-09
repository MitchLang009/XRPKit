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
import BigInt

let HASH_TX_SIGN: [UInt8] = [0x53,0x54,0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73,0x74,0x78,0x00]

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
    
    public static func generateWallet(seed: String) -> Wallet {
        let entropy = decodeSeed(seed: seed)!
        var data = Data(entropy)
        let privateKeyPointer: UnsafeMutablePointer<UInt8> = data.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
        let result = Foo().generateKP(privateKeyPointer)
        let results = result as! [String]
        let myPrivateKey = results[0].uppercased()
        let myPublicKey = results[1].uppercased()
        let mySecret = results[2]
        let myAccount = results[3]
        return Wallet(privateKey: myPrivateKey, publicKey: myPublicKey, seed: mySecret, account: myAccount)
    }
    
    public static func generateKeyPair(seed: String) throws -> KeyPairData {
        let seedData = XRP.decodeSeed(seed: seed)! + UInt32(0).data
        let secretKey = [0x00] + [UInt8](seedData.sha512().prefix(through: 31))
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
    
//    public static func generator() {
//        var privKey: BigInt = 0
//        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//        var seq = 0
//        repeat {
//
//        } while (privKey == 0) || privKey >= secp
//    }
    
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
        case invalidPrivateKey
        case invalidPublicKey
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
    
    public static func decodeSeed(seed: String) -> [UInt8]? {
        let versionEntropyCheck = [UInt8](Data(base58Decoding: seed)!)
        let check = Array(versionEntropyCheck.suffix(4))
        let versionEntropy = versionEntropyCheck.prefix(versionEntropyCheck.count-4)
        if check == [UInt8](Data(versionEntropy).sha256().sha256().prefix(through: 3)) {
            if versionEntropy[0] == 0x21 {
                let entropy = Array(versionEntropy.suffix(versionEntropy.count-1))
                return entropy
            }
        }
        return nil
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

public class PrivateKey {
    public static var algorithmName = "secp256k1"
    let privKey: [UInt8]
    
    init(privKey: [UInt8]) {
        self.privKey = privKey
    }
    
    public static func fromHex(hexPrivKey: String) -> PrivateKey {
        return PrivateKey(privKey: [UInt8](Data(hex: hexPrivKey)))
    }
    
    public func hex() -> String {
        return Data(self.privKey).toHexString()
    }
    
    public func getBytes() -> [UInt8] {
        return self.privKey
    }
}

public class PublicKey {
    public static var algorithmName = "secp256k1"
    let pubKey: [UInt8]
    
    init(pubKey: [UInt8]) {
        self.pubKey = pubKey
    }
    
    public static func fromHex(hexPubKey: String) -> PublicKey {
        return PublicKey(pubKey: [UInt8](Data(hex: hexPubKey)))
    }
    
    public func hex() -> String {
        return Data(self.pubKey).toHexString()
    }
    
    public func getBytes() -> [UInt8] {
        return self.pubKey
    }
}

public func getPublicKey(privateKey: PrivateKey) throws -> PublicKey {
    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
    var pubKey = secp256k1_pubkey()
    
    if secp256k1_ec_pubkey_create(ctx!, &pubKey, privateKey.getBytes()) == 0 {
        secp256k1_context_destroy(ctx)
        fatalError()
//        throw SigningError.invalidPrivateKey
    }
    
    var pubKeyBytes = [UInt8](repeating: 0, count: 33)
    var outputLen = 33
    _ = secp256k1_ec_pubkey_serialize(
        ctx!, &pubKeyBytes, &outputLen, &pubKey, UInt32(SECP256K1_EC_COMPRESSED))
    
    secp256k1_context_destroy(ctx)
    return PublicKey(pubKey: pubKeyBytes)
}

public func newRandomPrivateKey() -> PrivateKey {
    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
    let bytesCount = 32
    var randomBytes: [UInt8] = [UInt8](repeating: 0, count: bytesCount)
    
    repeat {
        _ = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
    } while secp256k1_ec_seckey_verify(ctx!, &randomBytes) != Int32(1)
    
    secp256k1_context_destroy(ctx)
    return PrivateKey(privKey: randomBytes)
}

//public func sign2(data: [UInt8], privateKey: String) throws -> Data {
//    let data: [UInt8] = HASH_TX_SIGN.bigEndian.data + data
//    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//    let context = Secp256k1Context()
//    
//    let privateKey = Secp256k1PrivateKey.fromHex(hexPrivKey: privateKey)
//    let signer = Signer(context: context, privateKey: privateKey)
//    
//    let actualSignature = try! signer.sign(data: data)
//
//    secp256k1_context_destroy(ctx)
//    return Data(hex: actualSignature)
//}

public func signNow(data: [UInt8], privateKey: [UInt8]) throws -> String {
    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
    var sig = secp256k1_ecdsa_signature()
    
    var _privateKey = Data(privateKey)
    var data = Data(data)
    let digestPointer: UnsafeMutablePointer<UInt8> = data.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
    let privateKeyPointer: UnsafeMutablePointer<UInt8> = _privateKey.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
    let resultSign = secp256k1_ecdsa_sign(ctx!, &sig, digestPointer, privateKeyPointer, secp256k1_nonce_function_rfc6979, nil)
    if resultSign == 0 {
        secp256k1_context_destroy(ctx)
        throw XRP.SigningError.invalidPrivateKey
    }
    var tmp: [UInt8] = Array(repeating: 0, count: 72)
    var size = tmp.count
    if secp256k1_ecdsa_signature_serialize_der(ctx!, &tmp[0], &size, &sig) == 0 {
        secp256k1_context_destroy(ctx)
        throw XRP.SigningError.invalidSignature
    }
    let ret = Data(tmp.prefix(through: size-1))
    secp256k1_context_destroy(ctx)
    return ret.toHexString()
}
public func signFinal(data: [UInt8], privateKey: [UInt8], publicKey: [UInt8]) throws -> String {
    let data: [UInt8] = HASH_TX_SIGN_TESTNET + data
    let _data: [UInt8] = myHash(data: data)
    let signature = try signNow(data: _data, privateKey: privateKey)
    print(signature)
    let verified = try verify(signature: signature, data: data, publicKey: publicKey)
    return signature
}

//public class Signer {
//    var context: Secp256k1Context
//    var privateKey: Secp256k1PrivateKey
//
//    public init(context: Secp256k1Context, privateKey: Secp256k1PrivateKey) {
//        self.context = context
//        self.privateKey = privateKey
//    }
//
//    /**
//     Produce a hex encoded signature from the data and the private key.
//     - Parameters:
//     - data: The bytes being signed.
//     - Returns: Hex encoded signature.
//     */
//    public func sign(data: [UInt8]) throws -> String {
//        return try self.context.sign(data: data, privateKey: self.privateKey)
//    }
//
//    /**
//     Get the public key associated with the private key.
//     - Returns: Public key associated with the signer's private key.
//     */
//    public func getPublicKey() throws -> Secp256k1PublicKey {
//        return try self.context.getPublicKey(privateKey: self.privateKey)
//    }
//}
//
//public func testSign() {
//    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//    let context = Secp256k1Context()
//
//    let privateKey = Secp256k1PrivateKey.fromHex(
//        hexPrivKey: "80378f103c7f1ea5856d50f2dcdf38b97da5986e9b32297be2de3c8444c38c08")
//    let signer = Signer(context: context, privateKey: privateKey)
//    let message: [UInt8] = Array("Hello, Alice, this is Bob.".utf8)
//
//    let actualSignature = try? signer.sign(data: message)
//
//    // This Signature was created with the Python sawtooth_signing library.
//    let expectedSignature = """
//        b7eec6dc1e4c3b64f0d5bae3f0e6be3978120c69ea1c8b5987921a869f36cb26\
//        2a4200527f9a06585a4d461281e008b929f7c4ec24880d2baf2a774cfc61969a
//        """
//
////    assert(actualSignature == expectedSignature)
//    secp256k1_context_destroy(ctx)
//}
//
//public func hash(data: [UInt8]) -> Data {
//    var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
//
//    _ = digest.withUnsafeMutableBytes { (digestBytes) in
//        CC_SHA256(data, CC_LONG(data.count), digestBytes)
//    }
//    return digest
//}
//
//public class Secp256k1Context {
//    public init() {}
//
//    public static var algorithmName = "secp256k1"
//
//    public func sign(data: [UInt8], privateKey: [Secp256k1PrivateKey]) throws -> String {
//        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//        var sig = secp256k1_ecdsa_signature()
//
//        let privateKey2 = privateKey.hex()
//
//        var msgDigest = Data(data.sha512().prefix(through: 31))
//        var resultSign = msgDigest.withUnsafeMutableBytes { (msgDigestBytes) in
//            secp256k1_ecdsa_sign(ctx!, &sig, msgDigestBytes, privateKey.getBytes(), secp256k1_nonce_function_rfc6979, nil)
//        }
//        if resultSign == 0 {
//            throw XRP.SigningError.invalidPrivateKey
//        }
//        var tmp: [UInt8] = Array(repeating: 0, count: 72)
//        var size = tmp.count
//        secp256k1_ecdsa_signature_serialize_der(ctx!, &tmp[0], &size, &sig)
//        let res = Data(tmp.prefix(through: size-1)).toHexString()
//        print(res)
//        secp256k1_context_destroy(ctx)
//        return res
//
////        var input: [UInt8] {
////            var tmp = sig.data
////            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
////        }
////        var compactSig = secp256k1_ecdsa_signature()
////
////        if secp256k1_ecdsa_signature_parse_compact(ctx!, &compactSig, input) == 0 {
////            secp256k1_context_destroy(ctx)
////            throw XRP.SigningError.invalidSignature
////        }
////
////        var csigArray: [UInt8] {
////            var tmp = compactSig.data
////            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
////        }
//
////        return Data(csigArray).toHexString()
//    }
//
////    public func sign(data: [UInt8], privateKey: Secp256k1PrivateKey) throws -> String {
////        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
////        var sig = secp256k1_ecdsa_signature()
////
////        var msgDigest = hash(data: data)
////        var resultSign = msgDigest.withUnsafeMutableBytes { (msgDigestBytes) in
////            secp256k1_ecdsa_sign(ctx!, &sig, msgDigestBytes, privateKey.getBytes(), nil, nil)
////        }
////        if resultSign == 0 {
////            throw XRP.SigningError.invalidPrivateKey
////        }
////
////        var input: [UInt8] {
////            var tmp = sig.data
////            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
////        }
//////        secp256k1_context_destroy(ctx)
//////        return Data(input).toHexString()
////
////        var compactSig = secp256k1_ecdsa_signature()
////
////        if secp256k1_ecdsa_signature_parse_compact(ctx!, &compactSig, input) == 0 {
////            secp256k1_context_destroy(ctx)
////            throw XRP.SigningError.invalidSignature
////        }
////
//////        var tmp: [UInt8] = Array(repeating: 0, count: 75)
//////        var size = 0
//////        secp256k1_ecdsa_signature_serialize_der(ctx!, &tmp[0], &size, &sig)
//////        let input2 = [UInt8](UnsafeBufferPointer(start: &tmp[0], count: size))
//////        let res = Data(input2).toHexString()
//////        print(res)
//////        return res
////
////        var csigArray: [UInt8] {
////            var tmp = compactSig.data
////            return [UInt8](UnsafeBufferPointer(start: &tmp.0, count: MemoryLayout.size(ofValue: tmp)))
////        }
////
////        secp256k1_context_destroy(ctx)
////        return Data(csigArray).toHexString()
////    }
//
//    public func getPublicKey(privateKey: Secp256k1PrivateKey) throws -> Secp256k1PublicKey {
//        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//        var pubKey = secp256k1_pubkey()
//
//        if secp256k1_ec_pubkey_create(ctx!, &pubKey, privateKey.getBytes()) == 0 {
//            secp256k1_context_destroy(ctx)
//            throw XRP.SigningError.invalidPrivateKey
//        }
//
//        var pubKeyBytes = [UInt8](repeating: 0, count: 33)
//        var outputLen = 33
//        _ = secp256k1_ec_pubkey_serialize(
//            ctx!, &pubKeyBytes, &outputLen, &pubKey, UInt32(SECP256K1_EC_COMPRESSED))
//
//        secp256k1_context_destroy(ctx)
//        return Secp256k1PublicKey(pubKey: pubKeyBytes)
//    }
//
//
//}
//
//public class Secp256k1PrivateKey {
//    public static var algorithmName = "secp256k1"
//    let privKey: [UInt8]
//
//    init(privKey: [UInt8]) {
//        self.privKey = privKey
//    }
//
//    public static func fromHex(hexPrivKey: String) -> Secp256k1PrivateKey {
//        return Secp256k1PrivateKey(privKey: [UInt8](Data(hex: hexPrivKey)))
//    }
//
//    public func hex() -> String {
//        return Data(self.privKey).toHexString()
//    }
//
//    public func getBytes() -> [UInt8] {
//        return self.privKey
//    }
//}
//
//public class Secp256k1PublicKey {
//    public static var algorithmName = "secp256k1"
//    let pubKey: [UInt8]
//
//    init(pubKey: [UInt8]) {
//        self.pubKey = pubKey
//    }
//
//    public static func fromHex(hexPubKey: String) -> Secp256k1PublicKey {
//        return Secp256k1PublicKey(pubKey: [UInt8](Data(hex: hexPubKey)))
//    }
//
//    public func hex() -> String {
//        return Data(self.pubKey).toHexString()
//    }
//
//    public func getBytes() -> [UInt8] {
//        return self.pubKey
//    }
//}
//
//
//public func runTests() {
//    let data =
//    [
//        ["1","Absence makes the heart grow fonder.","3045022100AFFF580595971B8C1700E77069D73602AEF4C2A760DBD697881423DFFF845DE80220579ADB6A1AC03ACDE461B5821A049EBD39A8A8EBF2506B841B15C27342D2E342"],
//        ["2","Actions speak louder than words.","304502210085F28BBC90975B1907A51CBFE7BF0DC1AC74ADE49318EE97498DBBDE3894A31C0220241D24DA8D263E7AF7FF49BCA6A7A850F0E087FAF6FEF44F85851B0283C3F026"],
//        ["3","All for one and one for all.","30440220502C6AC38E1C68CE68F044F5AB680F2880A6C1CD34E70F2B4F945C6FD30ABD03022018EF5C6C3392B9D67AD5109C85476A0E159425D7F6ACE2CEBEAA65F02F210BBB"],
//        ["4","All's fair in love and war.","30440220452D4AB234891CF6E5432CD5472BDCA1CFC6FB28563333885F068DA02EE216D8022056C368D16A64D29CFF92F17203D926E113064527AF0480D3BCC1D3FADFDE9364"],
//        ["5","All work and no play makes Jack a dull boy.","3045022100995025B4880EEB1ECEDBA945FE8C9B2DDF2B07DBC293C2586C079D7B663EF38A022022FB54AB95014616D014277E05C97A7ED9E22596A0420BBD2D749CA9A2F876FE"],
//        ["6","All's well that ends well.","3045022100A9C1593FA6459777B2EBA6D7E2A206E3BB119E85B2163973CF28FFAF24EC381C02202F166F13230B3853B928EFB649D30375EC6A4B1A64A8D56FBCC0A9D86A0943E9"],
//        ["7","An apple a day keeps the doctor away.","304402202FC9C8B749621241C33FD51B57FC5140C1D7FC1594F91B073953E79DA2F5E8F60220345E4EA7693B5069C0251771EA476CBE236586ED24B90AEEEA7B7C2814EDF477"],
//        ["8","An apple never falls far from the tree.","3044022052B6E2C49A6F6ADBE52FB6BBE744CAA3F49364085DB118EAB8670BC766BE160302207D96A42866637CA3D4CAF36E597A460EB305ADAC0220B027410C821A7191A1C4"],
//        ["9","An ounce of prevention is worth a pound of cure.","3045022100BE53E7C00788E4417083D7511800F18C7C6F5F259DE39BC6F8B1BEBCD5056BD002201F389E13CFE7D1DBD8D2D1BFF18138219F57DE166673762009686A28FBC44DF6"],
//        ["10","Appearances can be deceiving.","304402202F2413A1673F642C30EA2E23FCAE45776BC77A94F96920AEA3C14303B1469428022053AC3E8EA0A488E9159D56E429A51F207BF04E462F8D4BA2C69B1B1635F30217"],
//        ["34356466678672179216206944866734405838331831190171667647615530531663699592602","Absence makes the heart grow fonder.","3045022100996D79FBA54B24E9394FC5FAB6BF94D173F3752645075DE6E32574FE08625F770220345E638B373DCB0CE0C09E5799695EF64FFC5E01DD8367B9A205CE25F28870F6"],
//        ["99398763056634537812744552006896172984671876672520535998211840060697129507206","Actions speak louder than words.","304502210088164430985A4437471417C2386FAA536E1FE8EC91BD0F1F642BC22A776891530220090DC83D6E3B54A1A54DC2E79C693144179A512D9C9E686A6C25E7641A2101A8"],
//        ["3759719655879806965811134282268177329967523491661175987246621825209053686213","All for one and one for all.","30450221009F1073C9C09B664498D4B216983330B01C29A0FB55DD61AA145B4EBD0579905502204592FB6626F672D4F3AD4BB2D0A1ED6C2A161CC35C6BB77E6F0FD3B63FEAB36F"],
//        ["103660229287485550546857170818258546832194359524010586713457827121778385264241","All's fair in love and war.","304502210080EABF24117B492635043886E7229B9705B970CBB6828C4E03A39DAE7AC34BDA022070E8A32CA1DF82ADD53FACBD58B4F2D3984D0A17B6B13C44460238D9FF74E41F"],
//        ["104702657257102633579772822622124422673143939576486771274630765314225900831707","All work and no play makes Jack a dull boy.","3045022100A43FF5EDEA7EA0B9716D4359574E990A6859CDAEB9D7D6B4964AFD40BE11BD35022067F9D82E22FC447A122997335525F117F37B141C3EFA9F8C6D77B586753F962F"],
//        ["46744469262201639974910661553202053327388301297897803474665777634455660653814","All's well that ends well.","3044022053CE16251F4FAE7EB87E2AB040A6F334E08687FB445566256CD217ECE389E0440220576506A168CBC9EE0DD485D6C418961E7A0861B0F05D22A93401812978D0B215"],
//        ["91461772442478604154082755547318472082410323943823420797096392355159818037369","An apple a day keeps the doctor away.","3045022100DF8744CC06A304B041E88149ACFD84A68D8F4A2A4047056644E1EC8357E11EBE02204BA2D5499A26D072C797A86C7851533F287CEB8B818CAE2C5D4483C37C62750C"],
//        ["86354370597268376573642079301756246922349732255591245149271869674095200273050","An apple never falls far from the tree.","3045022100878372D211ED0DBDE1273AE3DD85AEC577C08A06A55960F2E274F97CC9F2F38F02203F992CAA66F472A64F6CCDD8076C0A12202C674155A6A61B8CD23C1DED08AAB7"],
//        ["19584093032798730129230525910686445865718710074652466673872143043325364812985","An ounce of prevention is worth a pound of cure.","3045022100D5CB4E148C0A29CE37F1542BE416E8EF575DA522666B19B541960D726C99662B022045C951C1CA938C90DAD6C3EEDE7C5DF67FCF0D14F90FAF201E8D215F215C5C18"],
//        ["781437121688497986836158713061237152541328908182646473971063062031575438443","Appearances can be deceiving.","304402203E2F0118062306E2239C873828A7275DD35545A143797E224148C5BBBD59DD08022073A8C9E17BE75C66362913B5E05D81FD619B434EDDA766FAE6C352E86987809D"]
//    ]
//    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//    let context = Secp256k1Context()
//
//    for datum in data {
//        let key = datum[0]
//        let message: [UInt8] = Array(datum[1].utf8)
//        let der = datum[2]
//
//        let privateKey = Secp256k1PrivateKey.fromHex(hexPrivKey: key)
//        let signer = Signer(context: context, privateKey: privateKey)
//
//        let actualSignature = try! signer.sign(data: message)
//        //    assert(actualSignature == expectedSignature)
//        let newder = actualSignature
//        print(der == newder)
//    }
//
//    secp256k1_context_destroy(ctx)
//
//
//}

public func verify(signature: String, data: [UInt8], publicKey: [UInt8]) throws-> Bool {
    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY))
    
    var sig = secp256k1_ecdsa_signature()
    
    var _signature = Data(hex: signature)
    let signature: UnsafeMutablePointer<UInt8> = _signature.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
    
    var _pubKeyData = Data(publicKey)
    let pubKeyData: UnsafeMutablePointer<UInt8> = _pubKeyData.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
    
    var _msgDigest = Data(myHash(data: data))
    let msgDigest: UnsafeMutablePointer<UInt8> = _msgDigest.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
    
    if secp256k1_ecdsa_signature_parse_der(ctx!, &sig, signature, _signature.count) == 0 {
        secp256k1_context_destroy(ctx)
        throw XRP.SigningError.invalidSignature
    }
    
    var pubKey = secp256k1_pubkey()
    let resultParsePublicKey = secp256k1_ec_pubkey_parse(ctx!, &pubKey, pubKeyData,
                                                         _pubKeyData.count)
    if resultParsePublicKey == 0 {
        secp256k1_context_destroy(ctx)
        throw XRP.SigningError.invalidPublicKey
    }
    
    let result = secp256k1_ecdsa_verify(ctx!, &sig, msgDigest, &pubKey)

    
    secp256k1_context_destroy(ctx)
    
    if result == 1 {
        return true
    } else {
        return false
    }
}

func myHash(data: [UInt8]) -> [UInt8] {
    return [UInt8](Data(data.sha512().prefix(through: 31)))
}
