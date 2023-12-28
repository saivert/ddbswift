import XCTest
@testable import ddbswift

final class ddbswiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var functions: DB_functions_t = DB_functions_t()

        let plugin = libddbswift_load(api: &functions)

        XCTAssertEqual(String(cString: plugin.pointee.plugin.name), "Swift DDB")
    }
}
