import sourcekitdInProc 
import Foundation

enum Error: ErrorProtocol {
    case sourcekit(String)
}

public func generate(funcString: String) throws -> String {
    let function = try parseFunction(funcString: funcString)
    return "\(function)"
}

struct Function {
    let name: String
    let params: [String]
    let returns: Bool
    let `throws`: Bool
}

func ==(lhs: Function, rhs: Function) -> Bool {
    return lhs.name     ==  rhs.name &&
           lhs.params   ==  rhs.params &&
           lhs.returns  ==  rhs.returns &&
           lhs.throws   ==  rhs.throws
}
extension Function: Equatable {}

private var sourceKitInitializationToken: dispatch_once_t = 0

func parseFunction(funcString: String) throws -> Function {

    dispatch_once(&sourceKitInitializationToken) {
        let library = toolchainLoader.load("sourcekitd.framework/Versions/A/sourcekitd")
        sourcekitd_initialize()
    }
    let req = "source.request.docinfo"

    let dict: [sourcekitd_uid_t : sourcekitd_object_t] = [
        sourcekitd_uid_get_from_cstr("key.request"): sourcekitd_request_uid_create(sourcekitd_uid_get_from_cstr(req)),
        sourcekitd_uid_get_from_cstr("key.sourcetext"): sourcekitd_request_string_create(funcString),
    ]
    var keys: [sourcekitd_uid_t?] = Array(dict.keys).flatMap{ $0 as sourcekitd_uid_t? }
    var values: [sourcekitd_object_t?] = Array(dict.values).flatMap { $0 as sourcekitd_object_t? }
    let requestObj = sourcekitd_request_dictionary_create(&keys, &values, dict.count)!

    guard let response = sourcekitd_send_request_sync(requestObj) else {
        throw Error.sourcekit("No response from sourcekit.")
    }
    defer { sourcekitd_response_dispose(response) }

    guard let sourcekitResponse = fromSourceKit(sourcekitd_response_get_value(response)) else {
        throw Error.sourcekit("nil response from sourcekit \(sourcekitd_response_get_value(response))")
    }
    guard case let result as [String:SourceKitRepresentable] = sourcekitResponse else {
        throw Error.sourcekit("Couldn't convert \(sourcekitResponse) to [String: SourceKitRepresentable]")
    }

    let outputData = try NSJSONSerialization.data(withJSONObject: toAnyObject(result) , options: .prettyPrinted)
    
    print(NSString(data: outputData, encoding: NSUTF8StringEncoding))

    let name = "the Name"
    return Function(name: name, params: [], returns: false, throws: false)
}

public protocol SourceKitRepresentable {
}
extension Array: SourceKitRepresentable {}
extension Dictionary: SourceKitRepresentable {}
extension String: SourceKitRepresentable {}
extension Int64: SourceKitRepresentable {}
extension Bool: SourceKitRepresentable {}
func fromSourceKit(_ sourcekitObject: sourcekitd_variant_t) -> SourceKitRepresentable? {
    switch sourcekitd_variant_get_type(sourcekitObject) {
    case SOURCEKITD_VARIANT_TYPE_ARRAY:
        var array = [SourceKitRepresentable]()
        sourcekitd_variant_array_apply(sourcekitObject) { index, value in
            if let value = fromSourceKit(value) {
                array.insert(value, at: Int(index))
            }
            return true
        }
        return array
    case SOURCEKITD_VARIANT_TYPE_DICTIONARY:
        var count: Int = 0
        sourcekitd_variant_dictionary_apply(sourcekitObject) { _, _ in
            count += 1
            return true
        }
        var dict = [String: SourceKitRepresentable](minimumCapacity: count)
        sourcekitd_variant_dictionary_apply(sourcekitObject) { key, value in
            if let key = stringForSourceKitUID(key!), value = fromSourceKit(value) {
                dict[key] = value
            }
            return true
        }
        return dict
    case SOURCEKITD_VARIANT_TYPE_STRING:
        let length = sourcekitd_variant_string_get_length(sourcekitObject)
        let ptr = sourcekitd_variant_string_get_ptr(sourcekitObject)!
        let string = swiftStringFrom(ptr, length: length)
        return string
    case SOURCEKITD_VARIANT_TYPE_INT64:
        return sourcekitd_variant_int64_get_value(sourcekitObject)
    case SOURCEKITD_VARIANT_TYPE_BOOL:
        return sourcekitd_variant_bool_get_value(sourcekitObject)
    case SOURCEKITD_VARIANT_TYPE_UID:
        return stringForSourceKitUID(sourcekitd_variant_uid_get_value(sourcekitObject))!
    case SOURCEKITD_VARIANT_TYPE_NULL:
        return nil
    default:
        fatalError("Should never happen because we've checked all SourceKitRepresentable types")
    }
}

private func swiftStringFrom(_ bytes: UnsafePointer<Int8>, length: Int) -> String? {
    let pointer = UnsafeMutablePointer<Int8>(bytes)
    // It seems SourceKitService returns string in other than NSUTF8StringEncoding.
    // We'll try another encodings if fail.
    let encodings = [NSUTF8StringEncoding, NSNEXTSTEPStringEncoding, NSASCIIStringEncoding]
    for encoding in encodings {
        if let string = String(bytesNoCopy: pointer, length: length, encoding: encoding,
            freeWhenDone: false) {
            return "\(string)"
        }
    }
    return nil
}

/// SourceKit UID to String map.
private var uidStringMap = [sourcekitd_uid_t: String]()

/**
Cache SourceKit requests for strings from UIDs

- parameter uid: UID received from sourcekitd* responses.

- returns: Cached UID string if available, nil otherwise.
*/
internal func stringForSourceKitUID(_ uid: sourcekitd_uid_t) -> String? {
    if let string = uidStringMap[uid] {
        return string
    }
    let length = sourcekitd_uid_get_length(uid)
    let bytes = sourcekitd_uid_get_string_ptr(uid)!
    if let uidString = swiftStringFrom(bytes, length: length) {
        /*
        `String` created by `String(UTF8String:)` is based on `NSString`.
        `NSString` base `String` has performance penalty on getting `hashValue`.
        Everytime on getting `hashValue`, it calls `decomposedStringWithCanonicalMapping` for
        "Unicode Normalization Form D" and creates autoreleased `CFString (mutable)` and
        `CFString (store)`. Those `CFString` are created every time on using `hashValue`, such as
        using `String` for Dictionary's key or adding to Set.
        
        For avoiding those penalty, replaces with enum's rawValue String if defined in SourceKitten.
        That does not cause calling `decomposedStringWithCanonicalMapping`.
        */
        uidStringMap[uid] = uidString
        return uidString
    }
    return nil
}

public func toAnyObject(_ dictionary: [String: SourceKitRepresentable]) -> [String: AnyObject] {
    var anyDictionary = [String: AnyObject]()
    for (key, object) in dictionary {
        switch object {
        case let object as AnyObject:
            anyDictionary[key] = object
        case let object as [SourceKitRepresentable]:
            anyDictionary[key] = object.map { toAnyObject($0 as! [String: SourceKitRepresentable]) }
        case let object as [[String: SourceKitRepresentable]]:
            anyDictionary[key] = object.map { toAnyObject($0) }
        case let object as [String: SourceKitRepresentable]:
            anyDictionary[key] = toAnyObject(object)
        case let object as String:
            anyDictionary[key] = object
        case let object as Int64:
            anyDictionary[key] = NSNumber(value: object)
        case let object as Bool:
            anyDictionary[key] = NSNumber(value: object)
        default:
            fatalError("Should never happen because we've checked all SourceKitRepresentable types")
        }
    }
    return anyDictionary
}

