//
//  Ledger.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import NIO

enum LedgerError: Error {
    case runtimeError(String)
}

public struct XRPLedger {
    
    // WebSocket is always available through SPM
    // WebSocket is only available through CocoaPods on newer OS
    #if canImport(WebSocketKit)
    public static var ws: XRPWebSocket = LinuxWebSocket()
    #elseif !os(Linux)
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
    public static var ws: XRPWebSocket = AppleWebSocket()
    #endif
    
    // JSON-RPC
    private static var url: URL = .xrpl_rpc_Testnet
    
    private init() {
        
    }
    
    public static func setURL(endpoint: URL) {
        self.url = endpoint
    }
    
    public static func getTxs(account: String) -> EventLoopFuture<[XRPHistoricalTransaction]> {
        
        let promise = eventGroup.next().makePromise(of: [XRPHistoricalTransaction].self)
        
        let parameters: [String: Any] = [
            "method" : "account_tx",
            "params": [
                [
                    "account" : account,
                    "ledger_index_min" : -1,
                    "ledger_index_max" : -1,
                ]
            ]
        ]
        
        _ = HTTP.post(url: url, parameters: parameters).map { (result) in
            let JSON = result as! NSDictionary
            let info = JSON["result"] as! NSDictionary
            let status = info["status"] as! String
            if status != "error" {
                let _array = info["transactions"] as! [NSDictionary]
                let filtered = _array.filter({ (dict) -> Bool in
                    let validated = dict["validated"] as! Bool
                    let tx = dict["tx"] as! NSDictionary
                    let meta = dict["meta"] as! NSDictionary
                    let res = meta["TransactionResult"] as! String
                    let type = tx["TransactionType"] as! String
                    return validated && type == "Payment" && res == "tesSUCCESS"
                })

                let transactions = filtered.map({ (dict) -> XRPHistoricalTransaction in
                    let tx = dict["tx"] as! NSDictionary
                    let destination = tx["Destination"] as! String
                    let source = tx["Account"] as! String
                    let amount = tx["Amount"] as! String
                    let timestamp = tx["date"] as! Int
                    let date = Date(timeIntervalSince1970: 946684800+Double(timestamp))
                    let type = account == source ? "Sent" : "Received"
                    let address = account == source ? destination : source
                    return XRPHistoricalTransaction(type: type, address: address, amount: try! XRPAmount(drops: Int(amount)!), date: date, raw: tx)
                })
                promise.succeed(transactions.sorted(by: { (lh, rh) -> Bool in
                    lh.date > rh.date
                }))
            } else {
                let errorMessage = info["error_message"] as! String
                let error = LedgerError.runtimeError(errorMessage)
                promise.fail(error)
            }
        }.recover { (error) in
            promise.fail(error)
        }
        
        return promise.futureResult
        
    }
    
    public static func getBalance(address: String) -> EventLoopFuture<XRPAmount> {
        
        let promise = eventGroup.next().makePromise(of: XRPAmount.self)
        
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : address
                ]
            ]
        ]
        _ = HTTP.post(url: url, parameters: parameters).map { (result) in
                let JSON = result as! NSDictionary
                let info = JSON["result"] as! NSDictionary
                let status = info["status"] as! String
                if status != "error" {
                    let account = info["account_data"] as! NSDictionary
                    let balance = account["Balance"] as! String
                    let amount = try! XRPAmount(drops: Int(balance)!)
                    promise.succeed( amount)
                } else {
                    let errorMessage = info["error_message"] as! String
                    let error = LedgerError.runtimeError(errorMessage)
                    promise.fail(error)
                }
        }.recover { (error) in
            promise.fail(error)
        }
        
        return promise.futureResult
    }
    
    public static func getAccountInfo(account: String) -> EventLoopFuture<XRPAccountInfo> {
        let promise = eventGroup.next().makePromise(of: XRPAccountInfo.self)
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : account,
                    "strict": true,
                    "ledger_index": "current",
                    "queue": true
                ]
            ]
        ]
        _ = HTTP.post(url: url, parameters: parameters).map { (result) in
                let JSON = result as! NSDictionary
                let info = JSON["result"] as! NSDictionary
                let status = info["status"] as! String
                if status != "error" {
                    let account = info["account_data"] as! NSDictionary
                    let balance = account["Balance"] as! String
                    let address = account["Account"] as! String
                    let sequence = account["Sequence"] as! Int
                    let accountInfo = XRPAccountInfo(address: address, drops: Int(balance)!, sequence: sequence)
                    promise.succeed( accountInfo)
                } else {
                    let errorMessage = info["error_message"] as! String
                    let error = LedgerError.runtimeError(errorMessage)
                    promise.fail(error)
                }
        }.recover { (error) in
            promise.fail(error)
        }
        return promise.futureResult
    }
    
    public static func getPendingEscrows(address: String) -> EventLoopFuture<NSDictionary> {
        
        let promise = eventGroup.next().makePromise(of: NSDictionary.self)
        
        let parameters: [String: Any] = [
            "method" : "account_objects",
            "params": [
                [
                    "account" : address,
                    "ledger_index": "validated",
                    "type": "escrow",
                ]
            ]
        ]
        _ = HTTP.post(url: url, parameters: parameters).map { (result) in
            let JSON = result as! NSDictionary
            let info = JSON["result"] as! NSDictionary
            let status = info["status"] as! String
            if status != "error" {
                promise.succeed( info)
            } else {
                let errorMessage = info["error_message"] as! String
                let error = LedgerError.runtimeError(errorMessage)
                promise.fail(error)
            }
        }.recover { (error) in
            promise.fail(error)
        }

        return promise.futureResult
        
    }
    
    public static func currentLedgerInfo() -> EventLoopFuture<XRPCurrentLedgerInfo> {
        let promise = eventGroup.next().makePromise(of: XRPCurrentLedgerInfo.self)
        let parameters: [String: Any] = [
            "method" : "fee"
        ]
        _ = HTTP.post(url: url, parameters: parameters).map { (result) in
            let JSON = result as! NSDictionary
            let info = JSON["result"] as! NSDictionary
            let drops = info["drops"] as! NSDictionary
            let min = drops["minimum_fee"] as! String
            let max = drops["median_fee"] as! String
            let ledger = info["ledger_current_index"] as! Int
            let ledgerInfo = XRPCurrentLedgerInfo(index: ledger, minFee: Int(min)!, maxFee: Int(max)!)
            promise.succeed( ledgerInfo)
        }.recover { (error) in
            promise.fail(error)
        }
        return promise.futureResult
    }
    
    public static func submit(txBlob: String) -> EventLoopFuture<NSDictionary> {
        let promise = eventGroup.next().makePromise(of: NSDictionary.self)
        let parameters: [String: Any] = [
            "method" : "submit",
            "params": [
                [
                    "tx_blob": txBlob
                ]
            ]
        ]
        _ = HTTP.post(url: url, parameters: parameters).map { (result) in
            let JSON = result as! NSDictionary
            let info = JSON["result"] as! NSDictionary
            promise.succeed( info)
        }.recover { (error) in
            promise.fail(error)
        }
        return promise.futureResult
    }
    
}
