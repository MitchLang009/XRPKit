//
//  Account.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

public enum SeedError: Error {
    case invalidSeed
}

public enum KeyPairError: Error {
    case invalidPrivateKey
}

public enum SeedType {
    case ed25519
    case secp256k1
}

public class XRPWallet {
    
    public var privateKey: String
    public var publicKey: String
    public var seed: String
    public var address: String
    
    private init(privateKey: String, publicKey: String, seed: String, address: String) {
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.seed = seed
        self.address = address
    }
    
    private convenience init(entropy: Entropy) {
        var data = Data(entropy.bytes)
        let privateKeyPointer: UnsafeMutablePointer<UInt8> = data.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
        let result = GeneratorWrapper().generateKP(privateKeyPointer)
        let results = result as! [String]
        self.init(privateKey: results[0].uppercased(), publicKey: results[1].uppercased(), seed: results[2], address: results[3])
    }
    
    /// Creates a random XRPWallet.
    public convenience init() {
        let entropy = Entropy()
        self.init(entropy: entropy)
    }

    /// Generates an XRPWallet from an existing family seed.
    ///
    /// - Parameter seed: amily seed using XRP alphabet and standard format.
    /// - Throws: SeedError
    public convenience init(seed: String) throws {
        let bytes = try XRPWallet.decodeSeed(seed: seed)!
        let entropy = Entropy(bytes: bytes)
        self.init(entropy: entropy)
    }
    
    /// Derive a standard XRP address from a public key.
    ///
    /// - Parameter publicKey: hexadecimal public key
    /// - Returns: standard XRP address encoded using XRP alphabet
    ///
    public static func deriveAddress(publicKey: String) -> String {
        let accountID = Data([0x00]) + RIPEMD160.hash(message: Data(hex: publicKey).sha256())
        let checksum = Data(accountID).sha256().sha256().prefix(through: 3)
        let addrrssData = accountID + checksum
        let address = String(base58Encoding: addrrssData)
        return address
    }
    
    /// Validates a String is a valid XRP address.
    ///
    /// - Parameter address: address encoded using XRP alphabet
    /// - Returns: true if valid
    ///
    public static func validate(address: String) -> Bool {
        if address.first != "r" {
            return false
        }
        if address.count < 25 || address.count > 35 {
            return false
        }
        if let _addressData = Data(base58Decoding: address) {
            var addressData = [UInt8](_addressData)
            // FIXME: base58Decoding
            addressData[0] = 0
            let accountID = [UInt8](addressData.prefix(addressData.count-4))
            let checksum = [UInt8](addressData.suffix(4))
            let _checksum = [UInt8](Data(accountID).sha256().sha256().prefix(through: 3))
            if checksum == _checksum {
                return true
            }
        }
        return false
    }
    
    /// Validates a String is a valid XRP family seed.
    ///
    /// - Parameter seed: seed encoded using XRP alphabet
    /// - Returns: true if valid
    ///
    public static func validate(seed: String) -> Bool {
        do {
            if let _ = try XRPWallet.decodeSeed(seed: seed) {
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    private static func encodeSeed(entropy: Entropy, type: SeedType) throws -> String {
        let version: [UInt8] = type == .ed25519 ? [0x01, 0xE1, 0x4B] : [0x21]
        let versionEntropy: [UInt8] = version + entropy.bytes
        let check = [UInt8](Data(versionEntropy).sha256().sha256().prefix(through: 3))
        let versionEntropyCheck: [UInt8] = versionEntropy + check
        return String(base58Encoding: Data(versionEntropyCheck), alphabet: Base58String.xrpAlphabet)
    }
    
    private static func decodeSeed(seed: String) throws -> [UInt8]? {
        // make sure seed will at least parse for checksum validation
        if seed.count < 10 || Data(base58Decoding: seed) == nil {
            throw SeedError.invalidSeed
        }
        let versionEntropyCheck = [UInt8](Data(base58Decoding: seed)!)
        let check = Array(versionEntropyCheck.suffix(4))
        let versionEntropy = versionEntropyCheck.prefix(versionEntropyCheck.count-4)
        if check == [UInt8](Data(versionEntropy).sha256().sha256().prefix(through: 3)) {
            if versionEntropy[0] == 0x21 {
                let entropy = Array(versionEntropy.suffix(versionEntropy.count-1))
                return entropy
            }
        }
        throw SeedError.invalidSeed
    }
    
}
