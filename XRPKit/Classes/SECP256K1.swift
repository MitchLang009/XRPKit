//
//  SECP256K1.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import secp256k1

let HASH_TX_SIGN: [UInt8] = [0x53,0x54,0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73,0x74,0x78,0x00]

public enum SigningError: Error {
    case invalidSignature
    case invalidPrivateKey
    case invalidPublicKey
}

public class SECP256K1 {
    
    public static func signNow(data: [UInt8], privateKey: [UInt8]) throws -> String {
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        var sig = secp256k1_ecdsa_signature()
        
        var _privateKey = Data(privateKey)
        var data = Data(data)
        let resultSign = secp256k1_ecdsa_sign(ctx!, &sig, data.getPointer(), _privateKey.getPointer(), secp256k1_nonce_function_rfc6979, nil)
        if resultSign == 0 {
            secp256k1_context_destroy(ctx)
            throw SigningError.invalidPrivateKey
        }
        var tmp: [UInt8] = Array(repeating: 0, count: 72)
        var size = tmp.count
        if secp256k1_ecdsa_signature_serialize_der(ctx!, &tmp[0], &size, &sig) == 0 {
            secp256k1_context_destroy(ctx)
            throw SigningError.invalidSignature
        }
        let ret = Data(tmp.prefix(through: size-1))
        secp256k1_context_destroy(ctx)
        return ret.toHexString()
    }
    
    public static func signFinal(data: [UInt8], privateKey: [UInt8], publicKey: [UInt8]) throws -> String {
        let privateKey = [UInt8](privateKey.suffix(from: 1))
        print(Data(privateKey).toHexString())
        print(Data(publicKey).toHexString())
        print(Data(data).toHexString())
        let data: [UInt8] = HASH_TX_SIGN_TESTNET + data
        let _data: [UInt8] = myHash(data: data)
        let signature = try signNow(data: _data, privateKey: privateKey)
        print(signature)
        let verified = try verify(signature: signature, data: data, publicKey: publicKey)
        if !verified {
            fatalError()
        }
        return signature
    }
    
    public static func verify(signature: String, data: [UInt8], publicKey: [UInt8]) throws-> Bool {
        
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY))
        var sig = secp256k1_ecdsa_signature()
        
        var _signatureData = Data(hex: signature)
        var _pubKeyData = Data(publicKey)
        var _msgDigest = Data(myHash(data: data))
        
        if secp256k1_ecdsa_signature_parse_der(ctx!, &sig, _signatureData.getPointer(), _signatureData.count) == 0 {
            secp256k1_context_destroy(ctx)
            throw SigningError.invalidSignature
        }
        
        var pubKey = secp256k1_pubkey()
        let resultParsePublicKey = secp256k1_ec_pubkey_parse(ctx!, &pubKey, _pubKeyData.getPointer(),
                                                             _pubKeyData.count)
        if resultParsePublicKey == 0 {
            secp256k1_context_destroy(ctx)
            throw SigningError.invalidPublicKey
        }
        
        let result = secp256k1_ecdsa_verify(ctx!, &sig, _msgDigest.getPointer(), &pubKey)
        
        
        secp256k1_context_destroy(ctx)
        
        if result == 1 {
            return true
        } else {
            return false
        }
    }
}
