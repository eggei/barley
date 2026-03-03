import Foundation

enum JSONValue: Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(any: Any) throws {
        if let value = any as? String {
            self = .string(value)
            return
        }

        if let value = any as? NSNumber {
            // NSNumber can represent Bool as well; distinguish by CF type.
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else {
                self = .number(value.doubleValue)
            }
            return
        }

        if let value = any as? [String: Any] {
            let mapped = try value.reduce(into: [String: JSONValue]()) { partialResult, item in
                partialResult[item.key] = try JSONValue(any: item.value)
            }
            self = .object(mapped)
            return
        }

        if let value = any as? [Any] {
            self = .array(try value.map(JSONValue.init(any:)))
            return
        }

        if any is NSNull {
            self = .null
            return
        }

        throw NSError(domain: "Barley.JSONValue", code: 1)
    }

    var foundationObject: Any {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return value
        case let .bool(value):
            return value
        case let .object(value):
            return value.mapValues { $0.foundationObject }
        case let .array(value):
            return value.map(\.foundationObject)
        case .null:
            return NSNull()
        }
    }

    var rendered: String {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return String(value)
        case let .bool(value):
            return String(value)
        case let .object(value):
            return "Object(\(value.count))"
        case let .array(value):
            return "Array(\(value.count))"
        case .null:
            return "null"
        }
    }
}
