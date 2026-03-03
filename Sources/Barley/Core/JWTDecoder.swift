import Foundation

struct DecodedJWT: Equatable {
    let header: [String: JSONValue]
    let payload: [String: JSONValue]
    let signature: String?
}

enum JWTDecodeError: LocalizedError, Equatable {
    case emptyToken
    case invalidTokenFormat
    case invalidBase64URLSegment(String)
    case invalidJSONSegment(String)
    case nonJSONObjectSegment(String)

    var errorDescription: String? {
        switch self {
        case .emptyToken:
            return "JWT is empty. Paste a token to decode."
        case .invalidTokenFormat:
            return "JWT must have 2 or 3 dot-separated segments."
        case let .invalidBase64URLSegment(segmentName):
            return "\(segmentName) segment is not valid Base64URL data."
        case let .invalidJSONSegment(segmentName):
            return "\(segmentName) segment is not valid JSON."
        case let .nonJSONObjectSegment(segmentName):
            return "\(segmentName) segment must decode to a JSON object."
        }
    }
}

enum JWTDecoder {
    static func decode(_ token: String) throws -> DecodedJWT {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw JWTDecodeError.emptyToken
        }

        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard (2...3).contains(parts.count) else {
            throw JWTDecodeError.invalidTokenFormat
        }

        let header = try decodeObjectSegment(parts[0], name: "Header")
        let payload = try decodeObjectSegment(parts[1], name: "Payload")
        let signature = parts.count == 3 && !parts[2].isEmpty ? parts[2] : nil

        return DecodedJWT(header: header, payload: payload, signature: signature)
    }

    static func prettyPrintedJSON(from object: [String: JSONValue]) -> String {
        let foundationObject = object.mapValues { $0.foundationObject }

        guard JSONSerialization.isValidJSONObject(foundationObject),
              let data = try? JSONSerialization.data(withJSONObject: foundationObject, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return string
    }

    private static func decodeObjectSegment(_ segment: String, name: String) throws -> [String: JSONValue] {
        let data = try decodeBase64URL(segment, name: name)

        let rawObject: Any
        do {
            rawObject = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw JWTDecodeError.invalidJSONSegment(name)
        }

        guard let dictionary = rawObject as? [String: Any] else {
            throw JWTDecodeError.nonJSONObjectSegment(name)
        }

        return try dictionary.reduce(into: [:]) { partialResult, item in
            partialResult[item.key] = try JSONValue(any: item.value)
        }
    }

    private static func decodeBase64URL(_ value: String, name: String) throws -> Data {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = base64.count % 4
        if padding != 0 {
            base64 += String(repeating: "=", count: 4 - padding)
        }

        guard let data = Data(base64Encoded: base64) else {
            throw JWTDecodeError.invalidBase64URLSegment(name)
        }

        return data
    }
}
