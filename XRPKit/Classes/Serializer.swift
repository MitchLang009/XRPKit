//
//  Serializer.swift
//  Alamofire
//
//  Created by Mitch Lang on 5/6/19.
//

import Foundation

private struct Definitions {
    var TYPES: [String: Int]
    var LEDGER_ENTRY_TYPES: [String : Int]
    var FIELDS: [String:FieldInfo]
    var TRANSACTION_RESULTS: [String : Int]
    var TRANSACTION_TYPES: [String : Int]
    
    init(dict: [String:AnyObject]) {
        self.TYPES = dict["TYPES"] as! [String:Int]
        self.LEDGER_ENTRY_TYPES = dict["LEDGER_ENTRY_TYPES"] as! [String:Int]
        self.TRANSACTION_RESULTS = dict["TRANSACTION_RESULTS"] as! [String:Int]
        self.TRANSACTION_TYPES = dict["TRANSACTION_TYPES"] as! [String:Int]
    
        let fields = dict["FIELDS"] as! [[AnyObject]]
        var fieldsDict: [String:FieldInfo] = [:]
        _ = fields.map { (array) in
            let field = array[0] as! String
            let fieldInfo = FieldInfo(dict: array[1] as! NSDictionary)
            fieldsDict[field] = fieldInfo
        }
        self.FIELDS = fieldsDict
    }
}

private struct FieldOrder {
    var name: String
    var orderTuple: OrderTuple
}

private struct OrderTuple {
    var typeCode: Int
    var order: Int
}

private struct TypeWrapper {
    var type: String
    var object: [String:Any]
}

private struct FieldInfo {
    var nth: Int
    var isVLEncoded: Bool
    var isSerialized: Bool
    var isSigningField: Bool
    var type: String
    
    init(dict: NSDictionary) {
        self.nth = dict["nth"] as! Int
        self.isVLEncoded = dict["isVLEncoded"] as! Bool
        self.isSerialized = dict["isSerialized"] as! Bool
        self.isSigningField = dict["isSigningField"] as! Bool
        self.type = dict["type"] as! String
        
    }
}

public class Serializer {
    
    // instance variables
    private var definitions: Definitions!
    
    // class variables
    public static let sharedInstance = Serializer()
    
    private init() {
        do {
            let asset = NSDataAsset(name: "definitions", bundle: Bundle(for: Serializer.self))
            let jsonResult = try JSONSerialization.jsonObject(with: asset!.data, options: .mutableLeaves)
            if let jsonResult = jsonResult as? [String:AnyObject] {
                self.definitions = Definitions(dict: jsonResult)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    private func fieldSortKey(fieldName: String) -> OrderTuple {
        // Return a tuple sort key for a given field name
        let fieldTypeName = definitions.FIELDS[fieldName]!.type
        let tuple = OrderTuple(typeCode: definitions.TYPES[fieldTypeName]!, order: definitions.FIELDS[fieldName]!.nth)
        return tuple
    }
    
    private func fieldID(fieldName: String) -> Data {
        
        if fieldName == "TxnSignature" {
            print(true)
        } else {
            print(false)
        }
        /*
        Returns the unique field ID for a given field name.
        This field ID consists of the type code and field code, in 1 to 3 bytes
        depending on whether those values are "common" (<16) or "uncommon" (>=16)
        */
        let field_type_name = definitions.FIELDS[fieldName]!.type
        let type_code = definitions.TYPES[field_type_name]!
        let field_code = definitions.FIELDS[fieldName]!.nth

        // Codes must be nonzero and fit in 1 byte
        assert(0 < field_code && field_code <= 255)
        assert(0 < type_code && type_code <= 255)

        if type_code < 16 && field_code < 16 {
            // high 4 bits is the type_code
            // low 4 bits is the field code
            let combined_code = (type_code << 4) | field_code
            return UInt8Byte(combined_code)
        } else if type_code >= 16 && field_code < 16 {
            // first 4 bits are zeroes
            // next 4 bits is field code
            // next byte is type code
            let byte1 = UInt8Byte(field_code)
            let byte2 = UInt8Byte(type_code)
            return byte1 + byte2
        } else if type_code < 16 && field_code >= 16 {
            // first 4 bits is type code
            // next 4 bits are zeroes
            // next byte is field code
            let byte1 = UInt8Byte(type_code << 4)
            let byte2 = UInt8Byte(field_code)
            return byte1 + byte2
        } else {
            // both are >= 16
            // first byte is all zeroes
            // second byte is type
            // third byte is field code
            let byte2 = UInt8Byte(type_code)
            let byte3 = UInt8Byte(field_code)
            return Data([0x00]) + byte2 + byte3
        }
    }
    
    private func vlEncode(contents: Data) -> Data {
        /*
         Helper function for length-prefixed fields including Blob types
         and some AccountID types.
         Encodes arbitrary binary data with a length prefix. The length of the prefix
         is 1-3 bytes depending on the length of the contents:
         Content length <= 192 bytes: prefix is 1 byte
         192 bytes < Content length <= 12480 bytes: prefix is 2 bytes
         12480 bytes < Content length <= 918744 bytes: prefix is 3 bytes
         */
        let contents = [UInt8](contents)
        var vl_len = contents.count
        if vl_len <= 192 {
            let len_byte = Data([UInt8(vl_len)])
            return len_byte + contents
        } else if vl_len <= 12480 {
            vl_len -= 193
            let byte1 = UInt8Byte((vl_len >> 8) + 193)
            let byte2 = UInt8Byte(vl_len & 0xff)
            return byte1 + byte2 + contents
        } else if vl_len <= 918744 {
            vl_len -= 12481
            let byte1 = UInt8Byte(241 + (vl_len >> 16))
            let byte2 = UInt8Byte((vl_len >> 8) & 0xff)
            let byte3 = UInt8Byte(vl_len & 0xff)
            return byte1 + byte2 + byte3 + contents
        }
        fatalError("VariableLength field must be <= 918744 bytes long")
    }
    
    private func accountIDToBytes(address: String) -> Data {
        /*
        Serialize an AccountID field type. These are length-prefixed.
        Some fields contain nested non-length-prefixed AccountIDs directly; those
        call decode_address() instead of this function.
        */
        let _array = [UInt8](Data(base58Decoding: address)!)
        let array = _array.prefix(_array.count-4)
        
        if array[0] == 0 || array.count == 21 {
            let addressData = Data(array.suffix(from: 1))
            return vlEncode(contents: addressData)
        } else {
            fatalError()
        }
    }
    
    private func amountToBytes(amount: String) -> Data {
        /*
         Serializes an "Amount" type, which can be either XRP or an issued currency:
         - XRP: 64 bits; 0, followed by 1 ("is positive"), followed by 62 bit UInt amount
         - Issued Currency: 64 bits of amount, followed by 160 bit currency code and
         160 bit issuer AccountID.
         */
        var xrp_amt = Int(amount)!
        let _edge = 100000000000000000 //10^17
        if (xrp_amt >= 0) {
            assert(xrp_amt <= _edge)
            // set the "is positive" bit -- this is backwards from usual two's complement!
            xrp_amt = xrp_amt | 0x4000000000000000
        } else {
            assert(xrp_amt >= -1*_edge)
            // convert to absolute value, leaving the "is positive" bit unset
            xrp_amt = -xrp_amt
        }
        return xrp_amt.bigEndian.data
    }
    
    private func arrayToBytes(array: [TypeWrapper]) -> Data {
        /*
        Serialize an array of objects from decoded JSON.
        Each member object must have a type wrapper and an inner object.
        For example:
        [
            {
                // wrapper object
                "Memo": {
                    // inner object
                    "MemoType": "687474703a2f2f6578616d706c652e636f6d2f6d656d6f2f67656e65726963",
                    "MemoData": "72656e74"
                }
            }
        ]
        */
        var members_as_bytes: [Data] = []
        for el in array {
            let wrapper_key = el.type
            let inner_obj = el.object
            members_as_bytes.append(fieldToBytes(fieldName: wrapper_key, fieldVal: inner_obj))
        }
        members_as_bytes.append(fieldID(fieldName: "ArrayEndMarker"))
        return members_as_bytes.reduce(Data(), { (result, newData) -> Data in
            return result + newData
        })
    }
    
    private func blobToBytes(hexBlob: String) -> Data {
        /*
        Serializes a string of hex as binary data with a length prefix.
        */
        return vlEncode(contents: hexBlob.hexadecimal!)
    }
    
    private func currencyCodeToBytes(code: String) -> Data {
        fatalError("currencyCodeToBytes not implemented")
    }
    
    private func hash128ToBytes(hexString: String) -> Data {
        // Serializes a hexadecimal string as binary and confirms that it's 128 bits
        let data = hashToBytes(hexString: hexString)
        if data.count != 16 {
            fatalError("hash128 is not 128 bits long")
        }
        return data
    }
    
    private func hash160ToBytes(hexString: String) -> Data {
        let data = hashToBytes(hexString: hexString)
        if data.count != 20 {
            fatalError("hash160 is not 160 bits long")
        }
        return data
    }
    
    private func hash256ToBytes(hexString: String) -> Data {
        let data = hashToBytes(hexString: hexString)
        if data.count != 32 {
            fatalError("hash256 is not 256 bits long")
        }
        return data
    }
    
    private func hashToBytes(hexString: String) -> Data {
        return hexString.hexadecimal!
    }
    
    private func objectToBytes(wrapper: TypeWrapper) -> Data {
        let wrapper_key = wrapper.type
        let inner_obj = wrapper.object
        let tuples = inner_obj.keys.map { (key) -> FieldOrder in
            let tuple = fieldSortKey(fieldName: key)
            return FieldOrder(name: key, orderTuple: tuple)
        }
        let sortedTuples = tuples.sorted { (lh, rh) -> Bool in
            if lh.orderTuple.typeCode == rh.orderTuple.typeCode {
                return lh.orderTuple.order < rh.orderTuple.order
            } else {
                return lh.orderTuple.typeCode < rh.orderTuple.typeCode
            }
        }
        var fieldAsBytes: [Data] = []
        for tuple in sortedTuples {
            if definitions.FIELDS[tuple.name]!.isSerialized {
                let fieldVal = inner_obj[tuple.name]!
                let bytes = fieldToBytes(fieldName: tuple.name, fieldVal: fieldVal)
                fieldAsBytes.append(bytes)
            }
        }
        fieldAsBytes.append(fieldID(fieldName: "ObjectEndMarker"))
        return fieldAsBytes.reduce(Data(), { (result, newData) -> Data in
            return result + newData
        })
    }
    
    private func txTypeToBytes(type: String) -> Data {
        let type = UInt16(definitions.TRANSACTION_TYPES[type]!)
        return UInt16Bytes(type)
    }
    
    private func UInt8Byte(_ int: Int) -> Data {
        return Data([UInt8(int)])
    }
    
    private func UInt8Byte(_ int: UInt8) -> Data {
        return int.bigEndian.data
    }
    
    private func UInt16Bytes(_ int: UInt16) -> Data {
        return int.bigEndian.data
    }
    
    private func UInt32Bytes(_ int: UInt32) -> Data {
        return int.bigEndian.data
    }
    
    // ========================
    // Core serialization logic
    // ========================
    
    private func fieldToBytes(fieldName: String, fieldVal: Any) -> Data {
        
        if fieldName == "TxnSignature" {
            print(true)
        }
        
        let fieldType = definitions.FIELDS[fieldName]!.type
        let idPrefix = fieldID(fieldName: fieldName)
        
        // special case
        if fieldName == "TransactionType" {
            return idPrefix + txTypeToBytes(type: fieldVal as! String)
        }
        
        let dispatch = { (fieldType: String, fieldVal: Any) -> Data in
            switch fieldType {
            case "AccountID":
                let address = fieldVal as! String
                return self.accountIDToBytes(address: address)
            case "Amount":
                let amount = fieldVal as! String
                return self.amountToBytes(amount: amount)
            case "Blob":
                let hexBlob = fieldVal as! String
                return self.blobToBytes(hexBlob: hexBlob)
            case "Hash128":
                let hexString = fieldVal as! String
                return self.hash128ToBytes(hexString: hexString)
            case "Hash160":
                let hexString = fieldVal as! String
                return self.hash160ToBytes(hexString: hexString)
            case "Hash256":
                let hexString = fieldVal as! String
                return self.hash256ToBytes(hexString: hexString)
            case "PathSet":
                fatalError()
            case "STArray":
                let array = fieldVal as! [[String:Any]]
                let wrappers: [TypeWrapper] = array.map({ (dict) -> TypeWrapper in
                    let kv = dict.first!
                    let body = dict
                    return TypeWrapper(type: kv.key, object: body)
                })
                return self.arrayToBytes(array: wrappers)
            case "STObject":
                let dict = fieldVal as! [String:Any]
                let kv = dict.first!
                let body = kv.value as! [String:Any]
                let wrapper = TypeWrapper(type: kv.key, object: body)
                return self.objectToBytes(wrapper: wrapper)
            case "UInt8":
                let int = fieldVal as! UInt8
                return self.UInt8Byte(int)
            case "UInt16":
                let int = fieldVal as! UInt16
                return self.UInt16Bytes(int)
            case "UInt32":
                let int = fieldVal as! UInt32
                return self.UInt32Bytes(int)
            default:
                fatalError("Invalid field name")
            }
        }
        
        let fieldBinary = dispatch(fieldType, fieldVal)
        return idPrefix + fieldBinary
        
    }
    
    public func serializeTx(tx: [String:Any], forSigning: Bool = false) -> Data {
        /*
        Takes a transaction as decoded JSON and returns a bytes object representing
        the transaction in binary format.
        The input format should omit transaction metadata and the transaction
        should be formatted with the transaction instructions at the top level.
        ("hash" can be included, but will be ignored)
        If for_signing=True, then only signing fields are serialized, so you can use
        the output to sign the transaction.
        SigningPubKey and TxnSignature are optional, but the transaction can't
        be submitted without them.
        For example:
        {
          "TransactionType" : "Payment",
          "Account" : "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh",
          "Destination" : "ra5nK24KXen9AHvsdFTKHSANinZseWnPcX",
          "Amount" : {
             "currency" : "USD",
             "value" : "1",
             "issuer" : "rf1BiGeXwwQoi8Z2ueFYTEXSwuJYfV2Jpn"
          },
          "Fee": "12",
          "Flags": 2147483648,
          "Sequence": 2
        }
        */
        
        let tuples = tx.keys.map { (key) -> FieldOrder in
            let tuple = fieldSortKey(fieldName: key)
            return FieldOrder(name: key, orderTuple: tuple)
        }
        let sortedTuples = tuples.sorted { (lh, rh) -> Bool in
            if lh.orderTuple.typeCode == rh.orderTuple.typeCode {
                return lh.orderTuple.order < rh.orderTuple.order
            } else {
                return lh.orderTuple.typeCode < rh.orderTuple.typeCode
            }
        }
        var fieldAsBytes: [Data] = []
        for tuple in sortedTuples {
            if definitions.FIELDS[tuple.name]!.isSerialized {
                if forSigning && !definitions.FIELDS[tuple.name]!.isSigningField {
                    continue
                }
                let fieldVal = tx[tuple.name]!
                let bytes = fieldToBytes(fieldName: tuple.name, fieldVal: fieldVal)
                fieldAsBytes.append(bytes)
                print(tuple.name)
                printBytes([bytes])
                
            }
        }
        return fieldAsBytes.reduce(Data(), { (result, newData) -> Data in
            return result + newData
        })
    }
    
    func printBytes(_ bytes: [Data]) {
        let combined = bytes.reduce(Data(), { (result, newData) -> Data in
            return result + newData
        })
        print(combined.hexadecimal)
        print("""

""")
    }

}

typealias Byte = UInt8
enum Bit: Int {
    case zero, one
}

extension Data {
    var bytes: [Byte] {
        var byteArray = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
}

extension Byte {
    var bits: [Bit] {
        let bitsOfAbyte = 8
        var bitsArray = [Bit](repeating: Bit.zero, count: bitsOfAbyte)
        for (index, _) in bitsArray.enumerated() {
            // Bitwise shift to clear unrelevant bits
            let bitVal: UInt8 = 1 << UInt8(bitsOfAbyte - 1 - index)
            let check = self & bitVal
            
            if check != 0 {
                bitsArray[index] = Bit.one
            }
        }
        return bitsArray
    }
}

extension String {
    
    /// Create `Data` from hexadecimal string representation
    ///
    /// This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    var hexadecimal: Data? {
        var data = Data(capacity: self.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
    
}

extension Data {
    
    /// Hexadecimal string representation of `Data` object.
    
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }
            .joined()
    }
}

extension Numeric {
    var data: Data {
        var source = self
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}
