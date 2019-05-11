//
//  CodeSnippets.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

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
//
//public class PrivateKey {
//    public static var algorithmName = "secp256k1"
//    let privKey: [UInt8]
//    
//    init(privKey: [UInt8]) {
//        self.privKey = privKey
//    }
//    
//    public static func fromHex(hexPrivKey: String) -> PrivateKey {
//        return PrivateKey(privKey: [UInt8](Data(hex: hexPrivKey)))
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
//public class PublicKey {
//    public static var algorithmName = "secp256k1"
//    let pubKey: [UInt8]
//    
//    init(pubKey: [UInt8]) {
//        self.pubKey = pubKey
//    }
//    
//    public static func fromHex(hexPubKey: String) -> PublicKey {
//        return PublicKey(pubKey: [UInt8](Data(hex: hexPubKey)))
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
//public func getPublicKey(privateKey: PrivateKey) throws -> PublicKey {
//    let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//    var pubKey = secp256k1_pubkey()
//    
//    if secp256k1_ec_pubkey_create(ctx!, &pubKey, privateKey.getBytes()) == 0 {
//        secp256k1_context_destroy(ctx)
//        fatalError()
//        //        throw SigningError.invalidPrivateKey
//    }
//    
//    var pubKeyBytes = [UInt8](repeating: 0, count: 33)
//    var outputLen = 33
//    _ = secp256k1_ec_pubkey_serialize(
//        ctx!, &pubKeyBytes, &outputLen, &pubKey, UInt32(SECP256K1_EC_COMPRESSED))
//    
//    secp256k1_context_destroy(ctx)
//    return PublicKey(pubKey: pubKeyBytes)
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
//    return PrivateKey(privKey: randomBytes)
//}


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


