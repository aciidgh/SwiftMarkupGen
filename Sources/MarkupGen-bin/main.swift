import MarkupGen

do {
    let gen = try generate(funcString: "public func hello(cool a: Int, abc b: FooType) throws -> FooType {}")
    print(gen)
} catch {
    print("Error: \(error)")
}
