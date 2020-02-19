//
//  PrivateKey.swift
//  HDWalletKit
//
//  Created by Pavlo Boiko on 10/4/18.
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation
import CryptoSwift
import secp256k1
#if os(Linux)
    import Glibc
#endif


enum PrivateKeyType {
    case hd
    case nonHd
}

internal struct PrivateKey {
    internal let raw: Data
    internal let chainCode: Data
    internal let index: UInt32
    internal let coin: Coin
    private var keyType: PrivateKeyType
    
    internal init(seed: Data, coin: Coin) {
        let output = try! Data(CryptoSwift.HMAC(key: "Bitcoin seed".data(using: .ascii)!.bytes, variant: .sha512).authenticate(seed.bytes))
        self.raw = output[0..<32]
        self.chainCode = output[32..<64]
        self.index = 0
        self.coin = coin
        self.keyType = .hd
    }
    
    private init(privateKey: Data, chainCode: Data, index: UInt32, coin: Coin) {
        self.raw = privateKey
        self.chainCode = chainCode
        self.index = index
        self.coin = coin
        self.keyType = .hd
    }
    
    internal var publicKey: Data {
        var _data = raw
        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
        let data = try! Data(SECP256K1.derivePublicKey(ctx: ctx, secretKey: _data.getPointer()).compressed)
        secp256k1_context_destroy(ctx)
        return data
    }

    internal func wifCompressed() -> String {
        var data = Data()
        data += Data([coin.wifAddressPrefix])
        data += raw
        data += Data([UInt8(0x01)])
        data += data.sha256().sha256().prefix(4)
        return String(base58Encoding: data, alphabet: Base58String.btcAlphabet)
    }
    
    internal func get() -> String {
        switch self.coin {
        case .bitcoin: fallthrough
        case .litecoin: fallthrough
        case .dash: fallthrough
        case .bitcoinCash:
            return self.wifCompressed()
        case .ethereum:
            return self.raw.toHexString()
        }
    }
    
    internal func derived(at node:DerivationNode) -> PrivateKey {
        guard keyType == .hd else { fatalError() }
        let edge: UInt32 = 0x80000000
        guard (edge & node.index) == 0 else { fatalError("Invalid child index") }
        
        var data = Data()
        switch node {
        case .hardened:
            data += Data([UInt8(0)])
            data += raw
        case .notHardened:
            var _data = raw
            let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
            data += try! Data(SECP256K1.derivePublicKey(ctx: ctx, secretKey: _data.getPointer()).compressed)
            secp256k1_context_destroy(ctx)
        }
        
        #if os(Linux)
            let derivingIndex = Glibc.ntohl(node.hardens ? (edge | node.index) : node.index)
        #else
            let derivingIndex = CFSwapInt32BigToHost(node.hardens ? (edge | node.index) : node.index)
        #endif
        data += derivingIndex.data
        
        let digest = try! Data(HMAC.init(key: chainCode.bytes, variant: .sha512).authenticate(data.bytes))
        let factor = BInt(data: digest[0..<32])
        
        let curveOrder = BInt(hex: "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")!
        let derivedPrivateKey = ((BInt(data: raw) + factor) % curveOrder).data
        let derivedChainCode = digest[32..<64]
        return PrivateKey(
            privateKey: derivedPrivateKey,
            chainCode: derivedChainCode,
            index: derivingIndex,
            coin: coin
        )
    }
}
