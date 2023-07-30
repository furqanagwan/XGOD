import Foundation

enum IsoType: Equatable {
    case gdf
    case xgd3
    case xsf

    func rootOffset() -> UInt64 {
        switch self {
        case .gdf:
            return 0xfd90000
        case .xgd3:
            return 0x2080000
        case .xsf:
            return 0
        }
    }

    static func read(from data: Data) -> IsoType? {
        if check(data: data, isoType: .xsf) {
            return .xsf
        }

        if check(data: data, isoType: .gdf) {
            return .gdf
        }

        // Original code had no extra check here, simply returning Xgd3 as fallback.
        // https://github.com/eliecharra/iso2god-cli/blob/a3b266a5/Chilano/Xbox360/Iso/GDF.cs#L268

        if check(data: data, isoType: .xgd3) {
            return .xgd3
        }

        return nil
    }

    private static func check(data: Data, isoType: IsoType) -> Bool {
        let offset = 0x20 * SECTOR_SIZE + isoType.rootOffset()
        let range = offset..<(offset + 20)
        let expectedBytes: [UInt8] = Array("MICROSOFT*XBOX*MEDIA".utf8)

        return data[range] == expectedBytes
    }
}

