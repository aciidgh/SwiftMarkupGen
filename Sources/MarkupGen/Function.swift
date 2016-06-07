import Foundation

enum Error: ErrorProtocol {
    case sourcekit(String)
    case sourcekitResultError(String)
    case noFunctionDecl
}

struct Function {
    let name: String
    let params: [String]
    let returns: Bool
    let `throws`: Bool
}

func parseFunction(funcString: String) throws -> Function {
    let result = try requestDocInfo(str: funcString)

    guard case let entities as [SourceKitRepresentable] = result["key.entities"] else {
        throw Error.sourcekitResultError("No entities")
    }

    // Grab the first function decl.
    let maybeFirstEntity = entities.flatMap{ $0 as? [String: SourceKitRepresentable] }
            .filter{ (($0["key.kind"] as? String) ?? "").hasPrefix("source.lang.swift.decl.function") }.first
    
    // If we don't find any function decl, no need to proceed.
    guard let firstEntity = maybeFirstEntity else { throw Error.noFunctionDecl }

    guard case let name as String = firstEntity["key.name"] else {
        throw Error.sourcekitResultError("No name")
    }

    var params = [String]()
   
    if case let paramEntities as [SourceKitRepresentable] = firstEntity["key.entities"] {
        for case let param as [String: SourceKitRepresentable] in paramEntities {
            guard case let keyword as String = param["key.keyword"],
                  case let name as String = param["key.name"] else { continue }
            params.append(keyword == "_" ? name : keyword)
        }
    }

    // Just find if function returns and throws from the signature.
    let returns = (funcString as NSString).contains("->")
    let `throws` = (funcString as NSString).contains("throws")

    return Function(name: name, params: params, returns: returns, throws: `throws`)
}

func ==(lhs: Function, rhs: Function) -> Bool {
    return lhs.name     ==  rhs.name &&
           lhs.params   ==  rhs.params &&
           lhs.returns  ==  rhs.returns &&
           lhs.throws   ==  rhs.throws
}
extension Function: Equatable {}
