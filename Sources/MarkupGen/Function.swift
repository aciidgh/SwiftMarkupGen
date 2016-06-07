import Foundation

enum Error: ErrorProtocol {
    case sourcekit(String)
    case sourcekitResultError(String)
}

struct Function {
    let name: String
    let params: [String]
    let returns: Bool
    let `throws`: Bool
}

func parseFunction(funcString: String) throws -> Function {
    let result = try requestDocInfo(str: funcString)

    // We only need the first entity.
    guard case let entities as [SourceKitRepresentable] = result["key.entities"],
          case let firstEntity as [String: SourceKitRepresentable] = entities.first else {
        throw Error.sourcekitResultError("No entities")
    }

    guard case let annotation as String = firstEntity["key.fully_annotated_decl"],
          case let name as String = firstEntity["key.name"] else {
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

    let returns = (annotation as NSString).contains("returntype")
    let `throws` = (annotation as NSString).contains("throws")

    return Function(name: name, params: params, returns: returns, throws: `throws`)
}

func ==(lhs: Function, rhs: Function) -> Bool {
    return lhs.name     ==  rhs.name &&
           lhs.params   ==  rhs.params &&
           lhs.returns  ==  rhs.returns &&
           lhs.throws   ==  rhs.throws
}
extension Function: Equatable {}
