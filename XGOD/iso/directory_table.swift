import Foundation

struct DirectoryTable {
    let sector: UInt32
    let size: UInt32
    let entries: [DirectoryEntry]
}

struct DirectoryEntry {
    let attributes: DirectoryEntryAttributes
    let name: String
    let nameLength: UInt8
    let sector: UInt32
    let size: UInt32
    let subtreeLeft: UInt16
    let subtreeRight: UInt16
    let subdirectory: DirectoryTable?
}

struct DirectoryEntryAttributes: OptionSet {
    let rawValue: UInt8
    
    static let archive = DirectoryEntryAttributes(rawValue: 0x20)
    static let directory = DirectoryEntryAttributes(rawValue: 0x10)
    static let hidden = DirectoryEntryAttributes(rawValue: 0x02)
    static let normal = DirectoryEntryAttributes(rawValue: 0x80)
    static let readOnly = DirectoryEntryAttributes(rawValue: 0x01)
    static let system = DirectoryEntryAttributes(rawValue: 0x04)
}

extension DirectoryTable {
    static func readRoot(reader: DataReader, volume: VolumeDescriptor) throws -> DirectoryTable {
        return try read(reader: reader, volume: volume, sector: volume.rootDirectorySector, size: volume.rootDirectorySize)
    }
    
     static func read(reader: DataReader, volume: VolumeDescriptor, sector: UInt32, size: UInt32) throws -> DirectoryTable {
        var entries: [DirectoryEntry] = []
        
        let sectorCount = Int((size + UInt32(SECTOR_SIZE) - 1) / UInt32(SECTOR_SIZE))
        for sectorIndex in 0..<sectorCount {
            let sectorPosition = UInt64(sector + UInt32(sectorIndex)) * volume.sectorSize + volume.rootOffset
            reader.seek(to: sectorPosition)
            
            while let entry = try DirectoryEntry.read(reader: reader, volume: volume) {
                entries.append(entry)
            }
        }
        
        return DirectoryTable(sector: sector, size: size, entries: entries)
    }
    
    func getEntry(name: String) -> DirectoryEntry? {
        return entries.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }
}

extension DirectoryEntry {
     static func read(reader: DataReader, volume: VolumeDescriptor) throws -> DirectoryEntry? {
        let subtreeLeft = try reader.readUInt16()
        let subtreeRight = try reader.readUInt16()
        
        if subtreeLeft == 0xffff || subtreeRight == 0xffff {
            return nil
        }
        
        let sector = try reader.readUInt32()
        let size = try reader.readUInt32()
        
        let attributesRawValue = try reader.readUInt8()
        let attributes = DirectoryEntryAttributes(rawValue: attributesRawValue)
        
        let nameLength = try reader.readUInt8()
        let nameBytes = try reader.readBytes(count: Int(nameLength))
        let name = String(bytes: nameBytes, encoding: .utf8) ?? ""
        
        let alignmentMismatch = (4 - reader.currentOffset % 4) % 4
        reader.seek(to: reader.currentOffset + UInt64(alignmentMismatch))
        
        let isDirectory = attributes.contains(.directory)
        let subdirectory: DirectoryTable? = isDirectory ? try DirectoryTable.read(reader: reader, volume: volume, sector: sector, size: size) : nil
        
        return DirectoryEntry(attributes: attributes, name: name, nameLength: nameLength, sector: sector, size: size, subtreeLeft: subtreeLeft, subtreeRight: subtreeRight, subdirectory: subdirectory)
    }
    
    var isDirectory: Bool {
        return attributes.contains(.directory)
    }
}

