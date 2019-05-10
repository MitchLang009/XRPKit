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
