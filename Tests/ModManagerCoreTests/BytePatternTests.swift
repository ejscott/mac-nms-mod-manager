import Foundation
import Testing
@testable import ModManagerCore

@Test func exactAndWildcardPatterns() {
    let data = Data([0xaa, 0x10, 0xcc, 0xaa, 0x20, 0xcc])
    #expect(BytePattern(hex: "aa ?? cc").findAll(in: data) == [0, 3])
    #expect(BytePattern(hex: "aa 10 cc").findAll(in: data) == [0])
}

@Test func patternRespectsSearchWindow() {
    let data = Data([1, 2, 3, 1, 2, 3])
    #expect(BytePattern(bytes: [1, 2, 3]).findAll(in: data, range: 2..<6) == [3])
}
