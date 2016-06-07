import XCTest
@testable import MarkupGen

class MarkupGenTests: XCTestCase {
    func testExample() {
        let gen = parseFunction(func: "func hello(a: Int, b: Double) {}")
        let theFunc = Function(name: "hello", params: ["a", "b"], returns: false, throws: false) 
        XCTAssertEqual(gen, theFunc)
    }

    static var allTests : [(String, (MarkupGenTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
