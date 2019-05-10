//
//  Ledger.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation
import Alamofire
import FutureKit

public class Ledger {
    
    private static let url = "https://s.altnet.rippletest.net:51234"//"https://s2.ripple.com:51234"
    private static let dataURL = "https://testnet.data.api.ripple.com/v2/"//"https://data.ripple.com/v2/"
    
    @available(iOS 10.0, *)
    public func getTransactions(account: String) -> Future<[TransactionHist]> {
        let p = Promise<[TransactionHist]>()
        let url = txHistURLFor(account: account)
        Alamofire.request(url, method:.get, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let _array = JSON["transactions"] as! [NSDictionary]
                        let transactions = _array.map({ (dict) -> TransactionHist in
                            let tx = dict["tx"] as! NSDictionary
                            let destination = tx["Destination"] as! String
                            let source = tx["Account"] as! String
                            let amount = tx["Amount"] as! String
                            let dateString = dict["date"] as! String
                            let dateFormatter = ISO8601DateFormatter()
                            let date = dateFormatter.date(from: dateString)
                            let type = account == source ? "Sent" : "Received"
                            let address = account == source ? destination : source
                            return TransactionHist(type: type, address: address, amount: Int(amount)!, date: date!)
                        })
                        
                        p.completeWithSuccess(transactions.sorted(by: { (lh, rh) -> Bool in
                            lh.date > rh.date
                        }))
                    }
                }
        }
        return p.future
    }
    
    @available(iOS 10.0, *)
    public func getBalance(account: String) -> Future<Int> {
        let p = Promise<Int>()
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : account
                ]
            ]
        ]
        Alamofire.request(Ledger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let status = info["status"] as! String
                        if status != "error" {
                            let account = info["account_data"] as! NSDictionary
                            let balance = account["Balance"] as! String
                            p.completeWithSuccess(Int(balance)!)
                        } else {
                            let error = info["error_message"] as! String
                            p.completeWithFail(error)
                        }
                    }
                }
        }
        return p.future
    }
    
    @available(iOS 10.0, *)
    public func getAccountInfo(account: String) -> Future<AccountInfo> {
        let p = Promise<AccountInfo>()
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
        
        Alamofire.request(Ledger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
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
                            p.completeWithSuccess(AccountInfo(address: address, drops: Int(balance)!, sequence: sequence))
                        } else {
                            let error = info["error_message"] as! String
                            p.completeWithFail(error)
                        }
                    }
                }
        }
        return p.future
    }
    
    public func currentLedgerInfo() -> Future<CurrentLedgerInfo> {
        let p = Promise<CurrentLedgerInfo>()
        let parameters: [String: Any] = [
            "method" : "fee"
        ]
        // abstract this
        Alamofire.request(Ledger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        let drops = info["drops"] as! NSDictionary
                        let min = drops["minimum_fee"] as! String
                        let max = drops["median_fee"] as! String
                        let ledger = info["ledger_current_index"] as! Int
                        p.completeWithSuccess(CurrentLedgerInfo(index: ledger, minFee: Int(min)!, maxFee: Int(max)!))
                    }
                }
        }
        return p.future
    }
    
    public func submit(txBlob: String) -> Future<Bool> {
        let p = Promise<Bool>()
        let parameters: [String: Any] = [
            "method" : "submit",
            "params": [
                [
                    "tx_blob": txBlob
                ]
            ]
        ]
        
        Alamofire.request(Ledger.url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                print(response)
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let info = JSON["result"] as! NSDictionary
                        p.completeWithSuccess(true)
                    }
                }
        }
        return p.future
    }
    
    private func txHistURLFor(account: String) -> String {
        return "\(Ledger.dataURL)accounts/\(account)/transactions?type=Payment&result=tesSUCCESS&limit=20"
    }
    
}
