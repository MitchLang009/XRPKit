//
//  HelperFunctions.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

public func drops2XRP(_ value: Int) -> String {
    let drops = value%1000000
    let xrp = value/1000000
    let length = String(drops).count
    let _leadingZeros = 6 - length
    let leadingZeros: [Character] = Array(repeating: "0", count: _leadingZeros)
    let ret = String(xrp) + "." + String(leadingZeros) + String(drops)
    return ret
}

extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}


extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    
    public func toHexString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

extension Data {

    init(hex: String) {
        var data = Data(capacity: hex.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hex, options: [], range: NSMakeRange(0, hex.count)) { match, flags, stop in
            let byteString = (hex as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }

        self = data
    }
}

extension Data {
    func sha512() -> Data {
        var hashData = Data(count: Int(CC_SHA512_DIGEST_LENGTH))
        
        var result = hashData.withUnsafeMutableBytes {digestBytes in
            self.withUnsafeBytes {messageBytes in
                CC_SHA512(messageBytes, CC_LONG(self.count), digestBytes)
            }
        }
        return Data(bytes: result!, count: 64)
    }
}
