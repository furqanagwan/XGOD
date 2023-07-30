import Foundation
import CommonCrypto

//public struct HashList {
//    private var buffer: Data
//
//    public init() {
//        buffer = Data(capacity: 4096)
//    }
//
//    // ... (rest of the HashList implementation, see the previous Swift code)
//
//    public func toBytes() -> [UInt8] {
//        var buf = Array(buffer)
//        buf.append(contentsOf: Array(repeating: 0, count: 4096 - buffer.count))
//        return buf
//    }
//}

enum Constants {
    static let BLOCKS_PER_PART: UInt64 = 0xa1c4
    static let BLOCKS_PER_SUBPART: UInt64 = 0xcc
    static let BLOCK_SIZE: Int = 0x1000
    static let FREE_SECTOR: UInt32 = 0x24
    static let SUBPARTS_PER_PART: UInt32 = 0xcb
}


public func writePart<R: Readable, W: Writable & Seekable>(_ src: inout R, _ dest: inout W) throws {
    var blockBuffer = Data(capacity: Constants.BLOCK_SIZE)
    var eof = false

    var masterHashList = HashList()

    let masterHashListPosition = try dest.streamPosition()
    try masterHashList.write(to: &dest)

    for _ in 0..<Constants.SUBPARTS_PER_PART {
        if eof {
            break
        }

        var subHashList = HashList()

        let subHashListPosition = try dest.streamPosition()
        try subHashList.write(to: &dest)

        for _ in 0..<Constants.BLOCKS_PER_SUBPART {
            let bytesRead = try src.read(into: &blockBuffer, maxLength: Constants.BLOCK_SIZE)

            if bytesRead == 0 {
                eof = true
                break
            }

            subHashList.addBlockHash(blockBuffer)
            try dest.write(blockBuffer)
            blockBuffer.removeAll()
        }

        let nextPosition = try dest.streamPosition()

        try dest.seek(to: subHashListPosition)
        try subHashList.write(to: &dest)

        masterHashList.addBlockHash(subHashList.toBytes())

        try dest.seek(to: nextPosition)
    }

    let nextPosition = try dest.streamPosition()

    try dest.seek(to: masterHashListPosition)
    try masterHashList.write(to: &dest)

    try dest.seek(to: nextPosition)
}

