import XCTest
@testable import sACN

final class sACNTests: XCTestCase {
    func testRootLayerTemplateDataCount() {
        XCTAssertEqual(rootLayerTemplate.count, 38)
    }
    func testDmxDataFramingLayerTemplateDataCount() {
        XCTAssertEqual(dmxDataFramingLayerTemplate.count, 77)
    }
    func testExample() {
        XCTAssertEqual(flagsAndLength(length: 1, flags: 0), UInt16(0b1).networkByteOrder)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
