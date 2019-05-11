//
//  SECP256K1.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import secp256k1

public enum SigningError: Error {
    case invalidSignature
    case invalidPrivateKey
    case invalidPublicKey
}

func sha512HalfHash(data: [UInt8]) -> [UInt8] {
    return [UInt8](Data(data).sha512().prefix(through: 31))
}

public class SECP256K1 {
    
    public static func sign(data: [UInt8], privateKey: [UInt8]) throws -> [UInt8] {
        
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        var sig = secp256k1_ecdsa_signature()
        
        var _privateKey = Data(privateKey)
        var _data = Data(sha512HalfHash(data: data))
        
        if secp256k1_ecdsa_sign(ctx!, &sig, _data.getPointer(), _privateKey.getPointer(), secp256k1_nonce_function_rfc6979, nil) == 0 {
            secp256k1_context_destroy(ctx)
            throw SigningError.invalidPrivateKey
        }
        
        var tmp: [UInt8] = Array(repeating: 0, count: 72)
        var size = tmp.count
        if secp256k1_ecdsa_signature_serialize_der(ctx!, &tmp[0], &size, &sig) == 0 {
            secp256k1_context_destroy(ctx)
            throw SigningError.invalidSignature
        }
        
        secp256k1_context_destroy(ctx)
        return [UInt8](tmp.prefix(through: size-1))
        
    }
    
    public static func verify(signature: [UInt8], data: [UInt8], publicKey: [UInt8]) throws -> Bool {
        
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY))
        var sig = secp256k1_ecdsa_signature()
        
        var _signatureData = Data(signature)
        var _pubKeyData = Data(publicKey)
        var _msgDigest = Data(sha512HalfHash(data: data))
        
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
