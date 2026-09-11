import Foundation

public struct BytePattern: Equatable, Sendable {
    public let bytes: [UInt8]
    public let mask: [UInt8]

    public init(bytes: [UInt8], mask: [UInt8]? = nil) {
        precondition(!bytes.isEmpty)
        precondition(mask == nil || mask?.count == bytes.count)
        self.bytes = bytes
        self.mask = mask ?? Array(repeating: 0xff, count: bytes.count)
    }

    public init(hex: String) {
        let tokens = hex.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
        var bytes: [UInt8] = []
        var mask: [UInt8] = []
        for token in tokens {
            if token == "??" {
                bytes.append(0)
                mask.append(0)
            } else {
                precondition(token.count == 2 && UInt8(token, radix: 16) != nil, "Invalid pattern token: \(token)")
                bytes.append(UInt8(token, radix: 16)!)
                mask.append(0xff)
            }
        }
        self.init(bytes: bytes, mask: mask)
    }

    public func matches(_ data: Data, at offset: Int) -> Bool {
        guard offset >= 0, offset + bytes.count <= data.count else { return false }
        return bytes.indices.allSatisfy { index in
            mask[index] == 0 || (data[offset + index] & mask[index]) == (bytes[index] & mask[index])
        }
    }

    public func findAll(in data: Data, range: Range<Int>? = nil) -> [Int] {
        let search = range ?? 0..<data.count
        guard search.lowerBound >= 0,
              search.upperBound <= data.count,
              search.count >= bytes.count else { return [] }
        return (search.lowerBound...(search.upperBound - bytes.count)).filter { matches(data, at: $0) }
    }
}
