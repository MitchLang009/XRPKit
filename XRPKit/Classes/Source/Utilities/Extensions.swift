//
//  Extensions.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

extension Data {
    mutating func getPointer() -> UnsafeMutablePointer<UInt8> {
        return self.withUnsafeMutableBytes { (bytePtr: UnsafeMutablePointer<UInt8>) in bytePtr }
    }
}
