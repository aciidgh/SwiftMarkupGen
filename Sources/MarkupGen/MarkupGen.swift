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

func parseFunction(funcString: String) throws -> Function {

    let result = try requestDocInfo(str: funcString)
    let outputData = try NSJSONSerialization.data(withJSONObject: toAnyObject(result) , options: .prettyPrinted)
    
    print(NSString(data: outputData, encoding: NSUTF8StringEncoding))

    let name = "the Name"
    return Function(name: name, params: [], returns: false, throws: false)
}

func ==(lhs: Function, rhs: Function) -> Bool {
    return lhs.name     ==  rhs.name &&
           lhs.params   ==  rhs.params &&
           lhs.returns  ==  rhs.returns &&
           lhs.throws   ==  rhs.throws
}
extension Function: Equatable {}
