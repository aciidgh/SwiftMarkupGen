//===--- Generate.swift ---------------------------------------------------===//
//
// Swift Markup Template Generator.
//
//===----------------------------------------------------------------------===//
//
//  Generates Markup.
//
//===----------------------------------------------------------------------===//

import Basic

public func generate(funcString: String) throws -> String {
    let function = try parseFunction(funcString: funcString)

    let stream = OutputByteStream()     
    stream <<< "/// \(function.name)\n"
    stream <<< "///"
    if !function.params.isEmpty {
        stream <<< "\n/// - Parameters:"
    }
    for param in function.params {
        stream <<< "\n///     - \(param): "
    }
    if function.throws {
        stream <<< "\n///"
        stream <<< "\n/// - Throws: "
    }
    if function.returns {
        stream <<< "\n///"
        stream <<< "\n/// - Returns: "
    }
    return stream.bytes.asString!
}
