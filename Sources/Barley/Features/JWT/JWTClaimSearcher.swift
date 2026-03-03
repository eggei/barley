import Foundation

struct ClaimEntry: Identifiable, Equatable {
    let path: String
    let value: String

    var id: String {
        "\(path)=\(value)"
    }
}

enum JWTClaimSearcher {
    static func flattenedClaims(from payload: [String: JSONValue]) -> [ClaimEntry] {
        var claims: [ClaimEntry] = []

        for key in payload.keys.sorted() {
            if let value = payload[key] {
                flatten(value: value, path: key, into: &claims)
            }
        }

        return claims
    }

    static func search(_ query: String, in claims: [ClaimEntry]) -> [ClaimEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return claims
        }

        let needle = trimmed.lowercased()
        return claims.filter {
            $0.path.lowercased().contains(needle) || $0.value.lowercased().contains(needle)
        }
    }

    private static func flatten(value: JSONValue, path: String, into claims: inout [ClaimEntry]) {
        switch value {
        case let .object(object):
            for key in object.keys.sorted() {
                if let child = object[key] {
                    flatten(value: child, path: "\(path).\(key)", into: &claims)
                }
            }
        case let .array(array):
            for (index, item) in array.enumerated() {
                flatten(value: item, path: "\(path)[\(index)]", into: &claims)
            }
        default:
            claims.append(ClaimEntry(path: path, value: value.rendered))
        }
    }
}
