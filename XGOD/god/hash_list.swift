import Foundation
import CommonCrypto

public struct HashList {
    private var buffer: Data

    init() {
        self.buffer = Data(capacity: 4096)
    }
    
    init(buffer: Data) {
        self.buffer = buffer
    }
    
//    public static func toBytes() -> [UInt8] {
//        var buf = Array(buffer)
//        buf.append(contentsOf: Array(repeating: 0, count: 4096 - buffer.count))
//        return buf
//    }

    public static func read(from reader: InputStream) throws -> HashList {
        reader.open()
        defer { reader.close() }

        var buffer = Data(capacity: 4096)
        var blockBuffer = Data(count: 20)

        while reader.hasBytesAvailable {
            let bytesRead = blockBuffer.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) -> Int in
                return reader.read(ptr.bindMemory(to: UInt8.self).baseAddress!, maxLength: 20)
            }

            if bytesRead <= 0 || blockBuffer.allSatisfy({ $0 == 0 }) {
                break
            }

            buffer.append(blockBuffer)
        }
        
        return HashList(buffer: buffer)
    }

    public mutating func addHash(_ hash: [UInt8]) {
        buffer.append(contentsOf: hash)
    }

    public mutating func addBlockHash(_ block: Data) {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        block.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(block.count), &digest)
        }
        addHash(digest)
    }

    public func digest() -> [UInt8] {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        buffer.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(buffer.count), &digest)
        }
        return digest
    }

    public func write(to writer: OutputStream) throws {
        writer.open()
        defer { writer.close() }

        try buffer.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            var bytesRemaining = buffer.count
            var bytesWritten = 0

            while bytesRemaining > 0 {
                let bytesSent = writer.write(ptr.bindMemory(to: UInt8.self).baseAddress!.advanced(by: bytesWritten), maxLength: bytesRemaining)
                if bytesSent < 0 {
                    throw writer.streamError ?? NSError()
                }
                bytesRemaining -= bytesSent
                bytesWritten += bytesSent
            }
        }
    }

    public func toBytes() -> [UInt8] {
        var buf = Array(buffer)
        buf.append(contentsOf: Array(repeating: 0, count: 4096 - buffer.count))
        return buf
    }
}

