import Foundation

public struct FileLayout {
    private let base_path: URL
    private let exe_info: XexExecutionInfo
    private let content_type: ContentType

    public init(basePath: URL, exeInfo: XexExecutionInfo, contentType: ContentType) {
        base_path = basePath
        exe_info = exeInfo
        content_type = contentType
    }

    private func titleIDString() -> String {
        return exe_info.titleId.map { String(format: "%02X", $0) }.joined().uppercased()
    }

    private func contentTypeString() -> String {
        return String(format: "%08X", content_type.rawValue)
    }

    private func mediaIDString() -> String {
        return exe_info.mediaId.map { String(format: "%02X", $0) }.joined().uppercased()
    }

    public func dataDirPath() -> URL {
        return base_path
            .appendingPathComponent(titleIDString())
            .appendingPathComponent(contentTypeString())
            .appendingPathComponent(mediaIDString() + ".data")
    }

    public func partFilePath(partIndex: UInt64) -> URL {
        return dataDirPath().appendingPathComponent("Data\(String(format: "%04d", partIndex))")
    }

    public func conHeaderFilePath() -> URL {
        return base_path
            .appendingPathComponent(titleIDString())
            .appendingPathComponent(contentTypeString())
            .appendingPathComponent(mediaIDString())
    }
}

