import Foundation

class Base64 {
    enum DecodingError: Swift.Error {
        case invalidData
    }
    
    static func decode(_ base64EncodedString: String) throws -> String {
        guard let base64EncodedData = base64EncodedString.data(using: .utf8),
              let data = Data(base64Encoded: base64EncodedData),
              let result = String(data: data, encoding: .utf8) else {
            throw DecodingError.invalidData
        }

        return result
    }
    
    static func encode(_ string: String) -> String {
        return Data(string.utf8).base64EncodedString()
    }
}
