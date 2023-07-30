import Foundation

let SECTOR_SIZE: UInt64 = 0x800

public struct IsoReader<R: ReadSeek> {
    public let volumeDescriptor: VolumeDescriptor
    let directoryTable: DirectoryTable
    private var reader: R

    public init(reader: R) throws {
        self.reader = reader
        self.volumeDescriptor = try VolumeDescriptor.read(from: &self.reader)
        self.directoryTable = try DirectoryTable.readRoot(from: &self.reader, with: volumeDescriptor)
    }

    public mutating func getRoot() -> R {
        self.reader.seek(to: volumeDescriptor.rootOffset)
        return self.reader
    }

    public mutating func getEntry(for path: WindowsPath) -> R? {
        var entry: DirectoryEntry?
        var directory: DirectoryTable? = self.directoryTable

        for name in path.components {
            entry = directory?.getEntry(name: name)
            directory = entry?.subdirectory
        }

        if let entry = entry {
            let position = volumeDescriptor.rootOffset + UInt64(entry.sector) * volumeDescriptor.sectorSize
            self.reader.seek(to: position)
            return self.reader
        } else {
            return nil
        }
    }
}

public struct WindowsPath {
    public let components: [String]

    init(_ path: String) {
        self.components = path.split(separator: "\\").map(String.init)
    }
}

