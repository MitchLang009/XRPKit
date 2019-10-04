# XRPKit

<div align="left">
    <img src="logo.png" width="250px"</img> 
</div>

[![Version](https://img.shields.io/cocoapods/v/XRPKit.svg?style=flat)](https://cocoapods.org/pods/XRPKit)
[![License](https://img.shields.io/cocoapods/l/XRPKit.svg?style=flat)](https://cocoapods.org/pods/XRPKit)
[![Platform](https://img.shields.io/cocoapods/p/XRPKit.svg?style=flat)](https://cocoapods.org/pods/XRPKit)

## NOT PRODUCTION READY 

This library is still under development and is not ready for production use.

NOTICE: Please see https://github.com/xpring-eng/xpringkit for an official Xpring SDK that was released before this project was finished.

## Installation

XRPKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'XRPKit'
```

## Wallets

### Create a new wallet

```swift

import XRPKit

// create a completely new, randomly generated wallet
let wallet = XRPWallet()

```

### Derive wallet from a seed

```swift

import XRPKit

// generate a wallet from an existing seed
let wallet = try! XRPWallet(seed: "snsTnz4Wj8vFnWirNbp7tnhZyCqx9")

```

### Wallet properties
```swift

import XRPKit

let wallet = XRPWallet()

print(wallet.address) // rJk1prBA4hzuK21VDK2vK2ep2PKGuFGnUD
print(wallet.seed) // snsTnz4Wj8vFnWirNbp7tnhZyCqx9
print(wallet.publicKey) // 02514FA7EF3E9F49C5D4C487330CC8882C0B4381BEC7AC61F1C1A81D5A62F1D3CF
print(wallet.privateKey) // 003FC03417669696AB4A406B494E6426092FD9A42C153E169A2B469316EA4E96B7

```

### Validation
```swift

import XRPKit

// Address
let btc = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
let xrp = "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK"

XRPWallet.validate(address: btc) // returns false
XRPWallet.validate(address: xrp) // returns true

// Seed
let seed = "shrKftFK3ZkMPkq4xe5wGB8HaNSLf"

XRPWallet.validate(seed: xrp) // returns false
XRPWallet.validate(seed: seed) // returns true

```

## Transactions

### Sending XRP
```swift

import XRPKit

let wallet = try! XRPWallet(seed: "shrKftFK3ZkMPkq4xe5wGB8HaNSLf")
let amount = try! XRPAmount(drops: 100000000)

let tx = XRPTransaction.send(from: wallet, to: "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK", amount: amount)
tx.onSuccess { (dict) -> () in
    print(dict)
}

```

### Sending XRP with custom fields
```swift

import XRPKit

let wallet = try! XRPWallet(seed: "shrKftFK3ZkMPkq4xe5wGB8HaNSLf")

let fields: [String:Any] = [
    "TransactionType" : "Payment",
    "Account" : wallet.address,
    "Destination" : "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK",
    "Amount" : "10000000",
    "Flags" : 2147483648,
    "LastLedgerSequence" : 951547,
    "Fee" : "40",
    "Sequence" : 11,
]

// create the transaction (offline)
let transaction = XRPTransaction(fields: fields)

// sign the transaction (offline)
let signedTransaction = try! transaction.sign(wallet: wallet)
    
// submit the transaction (online)
_ = signedTransaction.submit().onSuccess { (dict) in
    print(dict)
}

```


### Sending XRP with autofilled fields

```swift

import XRPKit

let wallet = try! XRPWallet(seed: "shrKftFK3ZkMPkq4xe5wGB8HaNSLf")

// dictionary containing partial transaction fields
let fields: [String:Any] = [
    "TransactionType" : "Payment",
    "Destination" : "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK",
    "Amount" : "100000000",
    "Flags" : 2147483648,
]

// create the transaction from dictionary
let partialTransaction = XRPTransaction(fields: fields)

// autofill missing transaction fields (online)
_ = partialTransaction.autofill(address: wallet.address).onSuccess { (transaction) -> () in
    
    // sign the transaction (offline)
    let signedTransaction = try! transaction.sign(wallet: wallet)
    
    // submit the transaction (online)
    _ = signedTransaction.submit().onSuccess { (dict) in
        print(dict)
    }
}

```

### Transaction Result 

```swift

//    SUCCESS: {
//        result =     {
//            "engine_result" = tesSUCCESS;
//            "engine_result_code" = 0;
//            "engine_result_message" = "The transaction was applied. Only final in a validated ledger.";
//            status = success;
//            "tx_blob" = 12000022800000002400000008201B000E83A6614000000005F5E100684000000000000028732102890EDF51199AEB1815324BA985C192D369B324AF6ABC1EBAD450E07EFBF5997E7446304402203765F06FB1D1D9FE942680A39C0925E95DC0AE18893268FDB5AF3CAFC5F6A87802201EFCE19E9C7ABBDD7C73F651A9AF6A323DDB4CE060A4CB63866512365830BEED81142B2DFB7FF7A2E9D8022144727A06141E4B3907248314F841A55DBAB1296D9A95F4CA8C05B721C1B0585C;
//            "tx_json" =         {
//                Account = rhAK9w7X64AaZqSWEhajcq5vhGtxEcaUS7;
//                Amount = 100000000;
//                Destination = rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK;
//                Fee = 40;
//                Flags = 2147483648;
//                LastLedgerSequence = 951206;
//                Sequence = 8;
//                SigningPubKey = 02890EDF51199AEB1815324BA985C192D369B324AF6ABC1EBAD450E07EFBF5997E;
//                TransactionType = Payment;
//                TxnSignature = 304402203765F06FB1D1D9FE942680A39C0925E95DC0AE18893268FDB5AF3CAFC5F6A87802201EFCE19E9C7ABBDD7C73F651A9AF6A323DDB4CE060A4CB63866512365830BEED;
//                hash = 4B709C7DFA8F8F396E4BB2CEACAFD61CA07000940736971AA788754267EE69AD;
//            };
//        };
//    }

```

## Ledger Info

### Check balance
```swift

import XRPKit

_ = XRPLedger.getBalance(address: "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK")
    .onSuccess { (amount) -> () in
        print(amount.prettyPrinted()) // 1,800.000000
    }

```

## Author

MitchLang009, mitch.s.lang@gmail.com

## License

XRPKit is available under the MIT license. See the LICENSE file for more info.
