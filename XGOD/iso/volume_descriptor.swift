import Foundation

public struct VolumeDescriptor {
    public let rootOffset: UInt64
    public let sectorSize: UInt64
    public let identifier: [UInt8]
    public let rootDirectorySector: UInt32
    public let rootDirectorySize: UInt32
    public let imageCreationTime: [UInt8]
    public let volumeSize: UInt64
    public let volumeSectors: UInt64

    public static func read<R: ReadSeek>(from reader: inout R) throws -> VolumeDescriptor {
        guard let isoType = try IsoType.read(from: &reader) else {
            throw NSError(domain: "VolumeDescriptor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid ISO format"])
        }
        return try self.read(ofType: isoType, from: &reader)
    }

    private static func read<R: ReadSeek>(ofType isoType: IsoType, from reader: inout R) throws -> VolumeDescriptor {
        try reader.seek(to: 0x20 * SECTOR_SIZE + isoType.rootOffset)

        var identifier = [UInt8](repeating: 0, count: 20)
        try reader.read(&mut identifier)

        let rootDirectorySector = try reader.readUInt32LittleEndian()
        let rootDirectorySize = try reader.readUInt32LittleEndian()

        // TODO: more specific type?
        var imageCreationTime = [UInt8](repeating: 0, count: 8)
        try reader.read(&mut imageCreationTime)

        let volumeSize = try reader.length() - isoType.rootOffset
        let volumeSectors = volumeSize / SECTOR_SIZE

        return VolumeDescriptor(
            rootOffset: isoType.rootOffset(),
            sectorSize: SECTOR_SIZE,
            identifier: identifier,
            rootDirectorySector: rootDirectorySector,
            rootDirectorySize: rootDirectorySize,
            imageCreationTime: imageCreationTime,
            volumeSize: volumeSize,
            volumeSectors: volumeSectors
        )
    }
}

