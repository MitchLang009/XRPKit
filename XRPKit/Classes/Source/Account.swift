//
//  Account.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

public enum KeyPairError: Error {
    case invalidPrivateKey
}

public enum SeedType {
    case ed25519
    case secp256k1
}

public enum EncodeSeedError: Error {
    case invalidBufferSize
    case invalidSeedType
}

public class Account {

    public func generateWallet(seed: String) -> XRPWallet {
        let entropy = decodeSeed(seed: seed)!
        var data = Data(entropy)
        let privateKeyPointer: UnsafeMutablePointer<UInt8> = data.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
        let result = GeneratorWrapper().generateKP(privateKeyPointer)
        let results = result as! [String]
        let myPrivateKey = results[0].uppercased()
        let myPublicKey = results[1].uppercased()
        let mySecret = results[2]
        let myAccount = results[3]
        return XRPWallet(privateKey: myPrivateKey, publicKey: myPublicKey, seed: mySecret, account: myAccount)
    }
    
    public func deriveAddress(publicKey: String) -> String {
        let accountID = Data([0x00]) + RIPEMD160.hash(message: Data(hex: publicKey).sha256())
        let checksum = accountID.sha256().sha256().prefix(through: 3)
        return String(base58Encoding: accountID + checksum)
    }
    
    public func entropy() -> [UInt8]? {
        var bytes = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        if status == errSecSuccess { // Always test the status.
            return bytes
        }
        return nil
    }
    
    public func encodeSeed(entropy: [UInt8], type: SeedType) throws -> String {
        if entropy.count != 16 {
            throw EncodeSeedError.invalidBufferSize
        }
        let version: [UInt8] = type == .ed25519 ? [0x01, 0xE1, 0x4B] : [0x21]
        let versionEntropy: [UInt8] = version + entropy
        let check = [UInt8](Data(versionEntropy).sha256().sha256().prefix(through: 3))
        let versionEntropyCheck: [UInt8] = versionEntropy + check
        return String(base58Encoding: Data(versionEntropyCheck), alphabet: Base58String.xrpAlphabet)
    }
    
    public func decodeSeed(seed: String) -> [UInt8]? {
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
