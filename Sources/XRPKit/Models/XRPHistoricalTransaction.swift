//
//  XRPHistoricalTransaction.swift
//  BigInt
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation

public struct XRPHistoricalTransaction {
    public var type: String
    public var address: String
    public var amount: XRPAmount
    public var date: Date
    public var raw: NSDictionary
}


/// Represents statuses of transactions.
public enum TransactionStatus: String {
    // The transaction was included in a finalized ledger and failed.
    case failed

    // The transaction is not included in a finalized ledger.
    case pending

    // The transaction was included in a finalized ledger and succeeded.
    case succeeded

    // The transaction status is unknown.
    case unknown
}

/// Represents statuses of transactions.
public enum TransactionResultType: String {
    // The transaction result was unspecified.
    case unspecified

    // The transaction result was tec.
    case tec

    // The transaction result was tef.
    case tef

    // The transaction result was tel.
    case tel

    // The transaction result was tem.
    case tem

    // The transaction result was ter.
    case ter

    // The transaction result was tes.
    case tes
}


/// Represents a transaction on the XRP Ledger.
public class LedgerTransactionRecept {

    /// Returns the validated statue of this `Transaction` on the XRP Ledger.
    public var validated: Bool?

    /// Returns a last ledger index corresponding to this `Transaction`.
    public var ledgerIndex: Int?

    /// Returns a `TransactionStatus for this `Transaction`.
    public var status: TransactionStatus?

    /// Returns the `TransactionResultType` corresponding to this `Transaction`.
    public var resultType: TransactionResultType?

    /// Returns the delivered amount as `XRPAmount` corresponding to this `Transaction`.
    public var deliveredAmount: XRPAmount?

    /// Returns a string transaction result corresponding to this `Transaction`.
    public var transactionResult: String { return "tecUNKNOWN" }

    /// Initialize a new `Transaction` with a transaction response from the xrp ledger.
    ///
    /// - Parameters:
    /// - receipt: A `NSDictionary` for the `Transaction`.
    /// - Returns: A new transaction if inputs were valid, otherwise nil.
    public convenience init?(receipt: NSDictionary) {
        self.init(transaction: receipt)
    }

    internal func parseTransactionStatus(resultType: TransactionResultType) -> TransactionStatus {
        // TODO: Finish Parsing
        switch resultType {
        case .tes:
            return TransactionStatus.succeeded
        case .tec:
            return TransactionStatus.failed
        default:
            return TransactionStatus.unknown
        }
    }

    /// Initialize a new `Transaction` backed by the given Get Tx Responset.
    // TODO: Return nil if not valid
    internal init(transaction: NSDictionary) {
        guard let validatedInt = transaction["validated"] as? Int, let _validated = validatedInt.boolValue else {
            return
        }
        self.validated = _validated
        guard let _ledgerIndex = transaction["ledger_index"] as? Int else {
            return
        }
        self.ledgerIndex = _ledgerIndex

        guard let meta = transaction["meta"] as? NSDictionary  else {
            return
        }
        guard let _txResult = meta["TransactionResult"] as? NSDictionary else {
            return
        }
        guard let _txResultTypeString = _txResult["result_type"] as? String, let _txResultType = TransactionResultType(rawValue: _txResultTypeString) else {
            return
        }
        self.resultType = _txResultType
        self.status = parseTransactionStatus(resultType: _txResultType)
        // Override Result if NOT Validated
        if self.validated == false {
            self.status = .pending
        }
        guard let _deliveredAmount = meta["delivered_amount"] as? NSDictionary else {
            return
        }
        self.deliveredAmount = _deliveredAmount
    }
}
