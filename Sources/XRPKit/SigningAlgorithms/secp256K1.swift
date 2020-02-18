//
//  SECP256K1.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import secp256k1
import BigInt

struct ECDSAPublicKey {
    var raw: secp256k1_pubkey
    var uncompressed: [UInt8]
    var compressed: [UInt8]
}

public enum SigningError: Error {
    case invalidSignature
    case invalidPrivateKey
    case invalidPublicKey
}

public enum SECP256K1Error: Error {
    case derivationFailed
}

class SECP256K1: SigningAlgorithm {
    
    static func deriveKeyPair(seed: [UInt8]) throws -> XRPKeyPair {
        
        // FIXME: NOT THE FULL DERIVATION PATH, SEE https://xrpl.org/cryptographic-keys.html#key-derivation
        
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
        
        // derive the root secret key
        var rootSecretKey = findSecretKey(ctx: ctx, startingKey: seed)

        // derive the root public key
        let rootPublicKey = try derivePublicKey(ctx: ctx, secretKey: rootSecretKey.getPointer())

        // derive intermediate secret key
        let tr: [UInt8] = [0, 0, 0, 0]
        var intermediateSecretKey = findSecretKey(ctx: ctx, startingKey: rootPublicKey.compressed + tr)
        
        // derive intermediate public key (useful for debugging)
        _ = try derivePublicKey(ctx: ctx, secretKey: intermediateSecretKey.getPointer())
        
        // derive master private key
        let bigRootPrivate = BigUInt(rootSecretKey.toHexString(), radix: 16)!
        let bigIntermediatePrivate = BigUInt(intermediateSecretKey.toHexString(), radix: 16)!
        let groupOrder = BigUInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
        let masterPrivateKey = ((bigRootPrivate + bigIntermediatePrivate) % groupOrder).serialize()
        var finalMasterPrivateKey = Data(repeating: 0x00, count: 33)
        finalMasterPrivateKey.replaceSubrange(1...masterPrivateKey.count, with: masterPrivateKey)
        
        // derive master public key
        var masterPrivateKeyForDerivation = Data(repeating: 0x00, count: 32)
        masterPrivateKeyForDerivation.replaceSubrange(32-masterPrivateKey.count...31, with: masterPrivateKey)
        let masterPublicKey = try derivePublicKey(ctx: ctx, secretKey: masterPrivateKeyForDerivation.getPointer()).compressed.toHexString()
        
        secp256k1_context_destroy(ctx)
        
        return XRPKeyPair(privateKey: finalMasterPrivateKey.toHexString(), publicKey: masterPublicKey)
        
    }
    
    private static func findSecretKey(ctx: OpaquePointer, startingKey: [UInt8], sequence: UInt32 = 0) -> Data {
        var potentialKey = Data(startingKey + sequence.bigEndian.data).sha512Half()
        if secp256k1_ec_seckey_verify(ctx, potentialKey.getPointer()) == 0 || potentialKey.checksum() == 0 {
            // invalid secret key, increment sequence
            return findSecretKey(ctx: ctx, startingKey: startingKey, sequence: sequence+1)
        } else {
            return potentialKey
        }
    }
    
    internal static func derivePublicKey(ctx: OpaquePointer, secretKey: UnsafePointer<UInt8>) throws -> ECDSAPublicKey {
        var _publicKey = secp256k1_pubkey()
        if secp256k1_ec_pubkey_create(ctx, UnsafeMutablePointer<secp256k1_pubkey>(&_publicKey), secretKey) == 0 {
            secp256k1_context_destroy(ctx)
            throw SECP256K1Error.derivationFailed
        }
        
        let uncompressedPublicKey = try serializePublicKey(ctx: ctx, publicKey: _publicKey, compressed: false)
        let compressedPublicKey = try serializePublicKey(ctx: ctx, publicKey: _publicKey, compressed: true)

        return ECDSAPublicKey(raw: _publicKey, uncompressed: uncompressedPublicKey, compressed: compressedPublicKey)
    }
    
    private static func serializePublicKey(ctx: OpaquePointer, publicKey: secp256k1_pubkey, compressed: Bool) throws -> [UInt8] {
        var _publicKey = publicKey
        let count = compressed ? 33 : 65
        var publicKey: [UInt8] = Array(repeating: 0, count: count)
        var size = publicKey.count
        let flags = compressed ? UInt32(SECP256K1_EC_COMPRESSED) : UInt32(SECP256K1_EC_UNCOMPRESSED)
        if secp256k1_ec_pubkey_serialize(ctx, &publicKey[0], &size, &_publicKey, flags) == 0 {
            secp256k1_context_destroy(ctx)
            throw SECP256K1Error.derivationFailed
        }
        return publicKey
    }
    
    static func sign(message: [UInt8], privateKey: [UInt8]) throws -> [UInt8] {
        
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
        var sig = secp256k1_ecdsa_signature()
        
        // remove one byte prefix from primary key
        let privateKey = [UInt8](privateKey.suffix(from: 1))
        
        var _privateKey = Data(privateKey)
        var _data = Data(sha512HalfHash(data: message))
        
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
    
    static func verify(signature: [UInt8], message: [UInt8], publicKey: [UInt8]) throws -> Bool {
        
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY))
        var sig = secp256k1_ecdsa_signature()
        
        var _signatureData = Data(signature)
        var _pubKeyData = Data(publicKey)
        var _msgDigest = Data(sha512HalfHash(data: message))
        
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
