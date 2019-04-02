//
//  XRP.swift
//  Alamofire
//
//  Created by Mitch Lang on 3/31/19.
//

import Foundation
import Alamofire
import FutureKit

public class XRP {
    private static let url = "https://s2.ripple.com:51234"
    private init() {}
    
    @available(iOS 10.0, *)
    public static func getTransactions(account: String) -> Future<[Transaction]> {
        let p = Promise<[Transaction]>()
        let url = txHistURLFor(account: account)
        Alamofire.request(url, method:.get, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                response.result.ifSuccess {
                    if let result = response.result.value {
                        let JSON = result as! NSDictionary
                        let _array = JSON["transactions"] as! [NSDictionary]
                        let transactions = _array.map({ (dict) -> Transaction in
                            let tx = dict["tx"] as! NSDictionary
                            let destination = tx["Destination"] as! String
                            let source = tx["Account"] as! String
                            let amount = tx["Amount"] as! String
                            let dateString = dict["date"] as! String
                            let dateFormatter = ISO8601DateFormatter()
                            let date = dateFormatter.date(from: dateString)
                            let type = account == source ? "Sent" : "Received"
                            let address = account == source ? destination : source
                            return Transaction(type: type, address: address, amount: Int(amount)!, date: date!)
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
    public static func getBalance(account: String) -> Future<Int> {
        let p = Promise<Int>()
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : account
                ]
            ]
        ]
        Alamofire.request(url, method:.post, parameters: parameters, encoding: JSONEncoding.default)
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
    
    private static func txHistURLFor(account: String) -> String {
        return "https://data.ripple.com/v2/accounts/\(account)/transactions?type=Payment&result=tesSUCCESS&limit=20"
    }
}
