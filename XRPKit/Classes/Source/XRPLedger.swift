//
//  Ledger.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import Alamofire
import FutureKit

public class XRPLedger {
    
    private static var url = "https://s.altnet.rippletest.net:51234"//"https://s2.ripple.com:51234"
    
    public static func setURL(endpoint: String) {
        self.url = endpoint
    }
    
    @available(iOS 10.0, *)
    public static func getTxs(account: String) -> Future<[XRPTransactionHist]> {
        let p = Promise<[XRPTransactionHist]>()
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
        Alamofire.request(XRPLedger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
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
                            
                            let transactions = filtered.map({ (dict) -> XRPTransactionHist in
                                let tx = dict["tx"] as! NSDictionary
                                let destination = tx["Destination"] as! String
                                let source = tx["Account"] as! String
                                let amount = tx["Amount"] as! String
                                let timestamp = tx["date"] as! Int
                                let date = Date(timeIntervalSince1970: 946684800+Double(timestamp))
                                let type = account == source ? "Sent" : "Received"
                                let address = account == source ? destination : source
                                return XRPTransactionHist(type: type, address: address, amount: try! XRPAmount(drops: Int(amount)!), date: date)
                            })
                            p.completeWithSuccess(transactions.sorted(by: { (lh, rh) -> Bool in
                                lh.date > rh.date
                            }))
                        } else {
                            let error = info["error_message"] as! String
                            p.completeWithFail(error)
                        }
                    }
                }
                response.result.ifFailure {
                    p.completeWithFail("Request failed.")
                }
        }
        return p.future
    }
    
    @available(iOS 10.0, *)
    public static func getBalance(address: String) -> Future<XRPAmount> {
        let p = Promise<XRPAmount>()
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : address
                ]
            ]
        ]
        Alamofire.request(XRPLedger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let status = info["status"] as! String
                        if status != "error" {
                            let account = info["account_data"] as! NSDictionary
                            let balance = account["Balance"] as! String
                            p.completeWithSuccess(try! XRPAmount(drops: Int(balance)!))
                        } else {
                            let error = info["error_message"] as! String
                            p.completeWithFail(error)
                        }
                    }
                }
                response.result.ifFailure {
                    p.completeWithFail("Request failed.")
                }
        }
        return p.future
    }
    
    @available(iOS 10.0, *)
    public static func getAccountInfo(account: String) -> Future<XRPAccountInfo> {
        let p = Promise<XRPAccountInfo>()
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
        
        Alamofire.request(XRPLedger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let status = info["status"] as! String
                        if status != "error" {
                            let account = info["account_data"] as! NSDictionary
                            let balance = account["Balance"] as! String
                            let address = account["Account"] as! String
                            let sequence = account["Sequence"] as! Int
                            p.completeWithSuccess(XRPAccountInfo(address: address, drops: Int(balance)!, sequence: sequence))
                        } else {
                            let error = info["error_message"] as! String
                            p.completeWithFail(error)
                        }
                    }
                }
                response.result.ifFailure {
                    p.completeWithFail("Request failed.")
                }
        }
        return p.future
    }
    
    public static func currentLedgerInfo() -> Future<XRPCurrentLedgerInfo> {
        let p = Promise<XRPCurrentLedgerInfo>()
        let parameters: [String: Any] = [
            "method" : "fee"
        ]
        // abstract this
        Alamofire.request(XRPLedger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let drops = info["drops"] as! NSDictionary
                        let min = drops["minimum_fee"] as! String
                        let max = drops["median_fee"] as! String
                        let ledger = info["ledger_current_index"] as! Int
                        p.completeWithSuccess(XRPCurrentLedgerInfo(index: ledger, minFee: Int(min)!, maxFee: Int(max)!))
                    }
                }
                response.result.ifFailure {
                    p.completeWithFail("Request failed.")
                }
        }
        return p.future
    }
    
    public static func submit(txBlob: String) -> Future<NSDictionary> {
        let p = Promise<NSDictionary>()
        let parameters: [String: Any] = [
            "method" : "submit",
            "params": [
                [
                    "tx_blob": txBlob
                ]
            ]
        ]
        
        Alamofire.request(XRPLedger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                print(response)
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        p.completeWithSuccess(info)
                    }
                }
                response.result.ifFailure {
                    p.completeWithFail("Request failed.")
                }
        }
        return p.future
    }
    
}
