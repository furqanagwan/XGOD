import Foundation

struct TitleList: Decodable {
    let items: [Title]
    let count: UInt32
    let pages: UInt32
    let page: UInt32
}

struct Title: Decodable {
    let titleId: String
    let hbTitleId: String
    let name: String
    let linkEnabled: Bool
    let titleType: TitleType
    let covers: UInt32
    let updates: UInt32
    let mediaIdCount: String
    let userCount: String
    let newestContent: String
}

extension Title: CustomStringConvertible {
    var description: String {
        return """
        Type: \(titleType)
        Title ID: \(titleId)
        Name: \(name)
        """
    }
}

enum TitleType: String, Decodable {
    case xbox = ""
    case xbox360 = "360"
    case xbla = "XBLA"
    case xbox1 = "Xbox1"
}

struct Client {
    let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 10
        config.timeoutIntervalForRequest = 10
        client = URLSession(configuration: config)
    }
    
    private func get(_ method: String) async throws -> Data {
        let url = URL(string: "http://xboxunity.net/\(method)")!
        let (data, _) = try await client.data(from: url)
        return data
    }
    
    private func search(_ searchStr: String) async throws -> TitleList {
        let method = "Resources/Lib/TitleList.php"
        let request = try await get(method + "?search=\(searchStr)")
        
        return try JSONDecoder().decode(TitleList.self, from: request)
    }
    
    func findXbox360Title(id: [UInt8]) async throws -> Title? {
        let searchString = id.map { String(format: "%02X", $0) }.joined()
        let titleList = try await search(searchString)
        
        let bestTitle = titleList.items.min {
            switch ($0.titleType, $1.titleType) {
            case (.xbox360, .xbox360), (.xbla, .xbox360):
                return $0.titleType.rawValue < $1.titleType.rawValue
            case (.xbla, .xbla):
                return $0.titleType.rawValue < $1.titleType.rawValue
            default:
                return $0.titleType.rawValue < $1.titleType.rawValue
            }
        }
        
        return bestTitle
    }
}

