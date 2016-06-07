import MarkupGen

import func libc.exit
import func libc.fputs
import var libc.stderr

class StandardErrorOutputStream: OutputStream {
    func write(_ string: String) {
        _ = libc.fputs(string, libc.stderr)
    }
}
var stderr = StandardErrorOutputStream()

@noreturn func usage() {
    let bin = Process.arguments[0]
    //     .........10.........20.........30.........40.........50.........60.........70..
    print("OVERVIEW: Generates Swift documentation markup for a given method.")
    print("")
    print("USAGE: \(bin) \"function string\"")
    print("")
    print("EXAMPLE:")
    print("\(bin) \"public func hello(cool a: Int, abc b: FooType) throws -> FooType {\"")
    print("")
    exit(1)
}

do {
    guard Process.arguments.count == 2 else {
        usage()
    }
    let argument = Process.arguments[1]
    //let gen = try generate(funcString: "public func hello(cool a: Int, abc b: FooType) throws -> FooType {}")
    let gen = try generate(funcString: argument)
    print(gen)
} catch {
    print("Error: \(error)", to: &stderr)
    exit(1)
}
