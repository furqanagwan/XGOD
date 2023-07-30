import Foundation

struct XexHeader {
    let moduleFlags: XexModuleFlags
    let codeOffset: UInt32
    let certificateOffset: UInt32
    let fields: XexHeaderFields
}

struct XexModuleFlags: OptionSet {
    let rawValue: UInt32
    
    static let titleModule = XexModuleFlags(rawValue: 0x01)
    static let exportsToTitle = XexModuleFlags(rawValue: 0x02)
    static let systemDebugger = XexModuleFlags(rawValue: 0x04)
    static let dllModule = XexModuleFlags(rawValue: 0x08)
    static let modulePatch = XexModuleFlags(rawValue: 0x10)
    static let fullPatch = XexModuleFlags(rawValue: 0x20)
    static let deltaPatch = XexModuleFlags(rawValue: 0x40)
    static let userMode = XexModuleFlags(rawValue: 0x80)
}

struct XexHeaderFields {
    var executionInfo: XexExecutionInfo?
    // Other fields will be added if and when necessary
}

enum XexHeaderFieldId: UInt32 {
    case resourceInfo = 0x000002ff
    case baseFileFormat = 0x000003ff
    case baseReference = 0x00000405
    case executionInfo = 0x00000406 // Corrected field name
    // Add other cases here with explicit raw values
}

struct XexExecutionInfo {
    let mediaId: [UInt8]
    let version: UInt32
    let baseVersion: UInt32
    let titleId: [UInt8]
    let platform: UInt8
    let executableType: UInt8
    let discNumber: UInt8
    let discCount: UInt8
}

extension XexHeader {
    static func read(from data: Data) throws -> XexHeader {
        let reader = DataReader(data: data)
        try checkMagicBytes(reader: reader)
        return try readChecked(reader: reader)
    }
    
    private static func checkMagicBytes(reader: DataReader) throws {
        let magicBytes = try reader.readBytes(count: 4)
        let expectedMagicBytes: [UInt8] = [0x58, 0x45, 0x58, 0x32] // UTF-8 representation of "XEX2"
        
        if magicBytes != expectedMagicBytes {
            throw XexHeaderError.missingMagicBytes
        }
    }
    
    private static func readChecked(reader: DataReader) throws -> XexHeader {
        let headerOffset = reader.currentOffset
        
        let _ = try reader.readUInt32() // Skip the first 4 bytes
        
        let moduleFlagsRaw = try reader.readUInt32()
        let moduleFlags = XexModuleFlags(rawValue: moduleFlagsRaw)
        
        let codeOffset = try reader.readUInt32()
        
        let _ = try reader.readUInt32() // Skip the next 4 bytes
        
        let certificateOffset = try reader.readUInt32()
        
        var fields = XexHeaderFields()
        
        let fieldCount = try reader.readUInt32()
        for _ in 0..<fieldCount {
            let key = try reader.readUInt32()
            let value = try reader.readUInt32()
            
            if let fieldId = XexHeaderFieldId(rawValue: key) {
                switch fieldId {
                case .executionInfo:
                    let offset = reader.currentOffset
                    reader.seek(to: headerOffset + UInt64(value))
                    fields.executionInfo = try XexExecutionInfo.read(from: reader)
                    reader.seek(to: offset)
                    // Add cases for other fields if needed
                    
                    // Add cases for other fields if needed
                    
                default:
                    // Handle unrecognized XexHeaderFieldId here (optional)
                    break
                }
            }
        }
        
        return XexHeader(moduleFlags: moduleFlags,
                         codeOffset: codeOffset,
                         certificateOffset: certificateOffset,
                         fields: fields)
    }
}

enum XexHeaderError: Error {
    case missingMagicBytes
    case endOfData
}

extension XexExecutionInfo {
    static func read(from reader: DataReader) throws -> XexExecutionInfo {
        let mediaId = try reader.readBytes(count: 4)
        let version = try reader.readUInt32()
        let baseVersion = try reader.readUInt32()
        let titleId = try reader.readBytes(count: 4)
        let platform = try reader.readUInt8()
        let executableType = try reader.readUInt8()
        let discNumber = try reader.readUInt8()
        let discCount = try reader.readUInt8()
        
        return XexExecutionInfo(mediaId: mediaId,
                                version: version,
                                baseVersion: baseVersion,
                                titleId: titleId,
                                platform: platform,
                                executableType: executableType,
                                discNumber: discNumber,
                                discCount: discCount)
    }
}

// Helper class to read data from a Data buffer
class DataReader {
    private var data: Data
    private var offset: Int
    
    init(data: Data) {
        self.data = data
        self.offset = 0
    }
    
    var currentOffset: UInt64 {
        return UInt64(offset)
    }
    
    func readBytes(count: Int) throws -> [UInt8] {
        guard offset + count <= data.count else {
            throw XexHeaderError.endOfData
        }
        let bytes = Array(data[offset..<offset + count])
        offset += count
        return bytes
    }
    
    func readUInt8() throws -> UInt8 {
        let byteData = try readBytes(count: 1)
        return byteData[0]
    }
    
    func readUInt16() throws -> UInt16 {
        let byteData = try readBytes(count: 2)
        return UInt16(byteData[0]) | (UInt16(byteData[1]) << 8)
    }
    
    func readUInt32() throws -> UInt32 {
        let byteData = try readBytes(count: 4)
        return byteData.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
    
    func seek(to position: UInt64) {
        offset = Int(position)
    }
}

