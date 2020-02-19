//
//  BigNumber.swift
//  HDWalletKit
//
//  Created by Pavlo Boiko on 1/6/19.
//  Copyright © 2019 Essentia. All rights reserved.
//

import Foundation

internal struct BigNumber {
    internal var int32: Int32
    internal var data: Data
    
    internal static let zero: BigNumber = BigNumber()
    internal static let one: BigNumber = BigNumber(1)
    internal static let negativeOne: BigNumber = BigNumber(1)
    
    internal init() {
        self.init(0)
    }
    
    internal init(_ int32: Int32) {
        self.int32 = int32
        self.data = int32.toBigNum()
    }
    
    internal init(int32: Int32) {
        self.int32 = int32
        self.data = int32.toBigNum()
    }
    
    internal init(_ data: Data) {
        self.data = data
        self.int32 = data.toInt32()
    }
}

extension BigNumber: Comparable {
    internal static func == (lhs: BigNumber, rhs: BigNumber) -> Bool {
        return lhs.int32 == rhs.int32
    }
    
    internal static func < (lhs: BigNumber, rhs: BigNumber) -> Bool {
        return lhs.int32 < rhs.int32
    }
}

private extension Int32 {
    func toBigNum() -> Data {
        let isNegative: Bool = self < 0
        var value: UInt32 = isNegative ? UInt32(-self) : UInt32(self)
        
        var data = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        while data.last == 0 {
            data.removeLast()
        }
        
        var bytes: [UInt8] = []
        for d in data.reversed() {
            if bytes.isEmpty && d >= 0x80 {
                bytes.append(0)
            }
            bytes.append(d)
        }
        
        if isNegative {
            let first = bytes.removeFirst()
            bytes.insert(first + 0x80, at: 0)
        }
        
        let bignum = Data(bytes.reversed())
        return bignum
        
    }
}

private extension Data {
    func toInt32() -> Int32 {
        guard !self.isEmpty else {
            return 0
        }
        var data = self
        var bytes: [UInt8] = []
        var last = data.removeLast()
        let isNegative: Bool = last >= 0x80
        
        while !data.isEmpty {
            bytes.append(data.removeFirst())
        }
        
        if isNegative {
            last -= 0x80
        }
        bytes.append(last)
        
        let value: Int32 = Data(bytes).to(type: Int32.self)
        return isNegative ? -value: value
    }
}

extension Data {
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
    
    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { (ptr) -> T in
            return ptr.baseAddress!.assumingMemoryBound(to: T.self).pointee
        }
    }
    
    func to(type: String.Type) -> String {
        return String(bytes: self, encoding: .ascii)!.replacingOccurrences(of: "\0", with: "")
    }
    
    func to(type: VarInt.Type) -> VarInt {
        let value: UInt64
        let length = self[0..<1].to(type: UInt8.self)
        switch length {
        case 0...252:
            value = UInt64(length)
        case 0xfd:
            value = UInt64(self[1...2].to(type: UInt16.self))
        case 0xfe:
            value = UInt64(self[1...4].to(type: UInt32.self))
        case 0xff:
            fallthrough
        default:
            value = self[1...8].to(type: UInt64.self)
        }
        return VarInt(value)
    }
}
