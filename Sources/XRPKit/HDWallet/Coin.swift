//
//  Coin.swift
//  HDWalletKit
//
//  Created by Pavlo Boiko on 10/3/18.
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation

internal enum Coin {
    case bitcoin
    case ethereum
    case litecoin
    case bitcoinCash
    case dash
    
    //https://github.com/satoshilabs/slips/blob/master/slip-0132.md
    internal var privateKeyVersion: UInt32 {
        switch self {
        case .litecoin:
            return 0x019D9CFE
        case .bitcoinCash: fallthrough
        case .bitcoin:
            return 0x0488ADE4
        case .dash:
            return 0x02FE52CC
        default:
            fatalError("Not implemented")
        }
    }
    // P2PKH
    internal var publicKeyHash: UInt8 {
        switch self {
        case .litecoin:
            return 0x30
        case .bitcoinCash: fallthrough
        case .bitcoin:
            return 0x00
        case .dash:
            return 0x4C
        default:
            fatalError("Not implemented")
        }
    }
    
    // P2SH
    internal var scriptHash: UInt8 {
        switch self {
        case .bitcoinCash: fallthrough
        case .litecoin: fallthrough
        case .bitcoin:
            return 0x05
        case .dash:
            return 0x10
        default:
            fatalError("Not implemented")
        }
    }
    
    //https://www.reddit.com/r/litecoin/comments/6vc8tc/how_do_i_convert_a_raw_private_key_to_wif_for/
    internal var wifAddressPrefix: UInt8 {
        switch self {
        case .bitcoinCash: fallthrough
        case .bitcoin:
            return 0x80
        case .litecoin:
            return 0xB0
        case .dash:
            return 0xCC
        default:
            fatalError("Not implemented")
        }
    }
    
    internal var addressPrefix:String {
        switch self {
        case .ethereum:
            return "0x"
        default:
            return ""
        }
    }
    
    internal var uncompressedPkSuffix: UInt8 {
        return 0x01
    }
    
    
    internal var coinType: UInt32 {
        switch self {
        case .bitcoin:
            return 0
        case .litecoin:
            return 2
        case .dash:
            return 5
        case .ethereum:
            return 60
        case .bitcoinCash:
            return 145
        }
    }
    
    internal var scheme: String {
        switch self {
        case .bitcoin:
            return "bitcoin"
        case .litecoin:
            return "litecoin"
        case .bitcoinCash:
            return "bitcoincash"
        case .dash:
            return "dash"
        default: return ""
        }
    }
}
