import Foundation
import CryptoKit


let EMPTY_LIVE: [UInt8] = [UInt8](repeating: 0, count: 0x186)

public struct ConHeaderBuilder {
    private var buffer: Data

    public init() {
        buffer = Data(EMPTY_LIVE)
    }

    public mutating func withBlockCounts(blocksAllocated: UInt32, blocksNotAllocated: UInt16) -> Self {
        buffer[0x0392] = UInt8((blocksAllocated >> 16) & 0xFF)
        buffer[0x0393] = UInt8((blocksAllocated >> 8) & 0xFF)
        buffer[0x0394] = UInt8(blocksAllocated & 0xFF)
        buffer[0x0395] = UInt8((blocksNotAllocated >> 8) & 0xFF)
        buffer[0x0396] = UInt8(blocksNotAllocated & 0xFF)
        return self
    }

    public mutating func withContentType(_ contentType: ContentType) -> Self {
        buffer[0x0344] = UInt8((contentType.rawValue >> 24) & 0xFF)
        buffer[0x0345] = UInt8((contentType.rawValue >> 16) & 0xFF)
        buffer[0x0346] = UInt8((contentType.rawValue >> 8) & 0xFF)
        buffer[0x0347] = UInt8(contentType.rawValue & 0xFF)
        return self
    }

    public mutating func withDataPartsInfo(partCount: UInt32, partsTotalSize: UInt64) -> Self {
        buffer[0x03A0] = UInt8((partCount >> 24) & 0xFF)
        buffer[0x03A1] = UInt8((partCount >> 16) & 0xFF)
        buffer[0x03A2] = UInt8((partCount >> 8) & 0xFF)
        buffer[0x03A3] = UInt8(partCount & 0xFF)

        let partsTotalSizeBE = partsTotalSize.byteSwapped
        buffer[0x03A4] = UInt8((partsTotalSizeBE >> 56) & 0xFF)
        buffer[0x03A5] = UInt8((partsTotalSizeBE >> 48) & 0xFF)
        buffer[0x03A6] = UInt8((partsTotalSizeBE >> 40) & 0xFF)
        buffer[0x03A7] = UInt8((partsTotalSizeBE >> 32) & 0xFF)
        buffer[0x03A8] = UInt8((partsTotalSizeBE >> 24) & 0xFF)
        buffer[0x03A9] = UInt8((partsTotalSizeBE >> 16) & 0xFF)
        buffer[0x03AA] = UInt8((partsTotalSizeBE >> 8) & 0xFF)
        buffer[0x03AB] = UInt8(partsTotalSizeBE & 0xFF)
        return self
    }

     mutating func withExecutionInfo(exeInfo: XexExecutionInfo) -> Self {
        let executionInfoBytes = [
            exeInfo.platform + UInt8(ascii: "0"),
            exeInfo.executableType + UInt8(ascii: "0"),
            exeInfo.discNumber + UInt8(ascii: "0"),
            exeInfo.discCount + UInt8(ascii: "0"),
        ]
        buffer.replaceSubrange(0x0364..<0x0368, with: executionInfoBytes)

        buffer.replaceSubrange(0x0360..<0x0370, with: exeInfo.titleId)
        buffer.replaceSubrange(0x0354..<0x035C, with: exeInfo.mediaId)

        return self
    }

    public mutating func withGameIcon(pngBytes: [UInt8]?) -> Self {
        let emptyBytes = [UInt8](repeating: 0, count: 20)
        let pngBytes = pngBytes ?? emptyBytes

        let pngBytesLength = UInt32(pngBytes.count)
        let pngBytesLengthBE = pngBytesLength.byteSwapped

        buffer[0x1712] = UInt8((pngBytesLengthBE >> 24) & 0xFF)
        buffer[0x1713] = UInt8((pngBytesLengthBE >> 16) & 0xFF)
        buffer[0x1714] = UInt8((pngBytesLengthBE >> 8) & 0xFF)
        buffer[0x1715] = UInt8(pngBytesLengthBE & 0xFF)

        buffer[0x171A] = UInt8((pngBytesLengthBE >> 24) & 0xFF)
        buffer[0x171B] = UInt8((pngBytesLengthBE >> 16) & 0xFF)
        buffer[0x171C] = UInt8((pngBytesLengthBE >> 8) & 0xFF)
        buffer[0x171D] = UInt8(pngBytesLengthBE & 0xFF)

        buffer.replaceSubrange(0x171A..<0x171A+Int(pngBytesLength), with: pngBytes)
        buffer.replaceSubrange(0x571A..<0x571A+Int(pngBytesLength), with: pngBytes)

        return self
    }

    public mutating func withGameTitle(gameTitle: String) -> Self {
        let gameTitleUtf16 = gameTitle.utf16
        for (index, codeUnit) in gameTitleUtf16.enumerated() {
            buffer[0x0411 + (index * 2)] = UInt8((codeUnit >> 8) & 0xFF)
            buffer[0x0411 + (index * 2) + 1] = UInt8(codeUnit & 0xFF)

            buffer[0x1691 + (index * 2)] = UInt8((codeUnit >> 8) & 0xFF)
            buffer[0x1691 + (index * 2) + 1] = UInt8(codeUnit & 0xFF)
        }

        return self
    }

    public mutating func withMhtHash(mhtHash: [UInt8]) -> Self {
        buffer.replaceSubrange(0x037D..<0x037D + mhtHash.count, with: mhtHash)
        return self
    }

    public mutating func finalize() -> Data {
        buffer[0x035B] = 0
        buffer[0x035F] = 0
        buffer[0x0391] = 0

        let conHeaderData = buffer.subdata(in: 0x0344..<(0x0344 + 0xACBC))

        let sha1Digest = Insecure.SHA1.hash(data: conHeaderData)
        let sha1Data = Data(sha1Digest) // Convert SHA-1 digest to Data

        buffer.replaceSubrange(0x032C..<0x032C + 20, with: sha1Data) // Use the Data object

        return buffer
    }
}

