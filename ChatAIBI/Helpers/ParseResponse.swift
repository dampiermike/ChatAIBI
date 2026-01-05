//
//  ParseResponse.swift
//  ChatAIBI
//
//  Created by Mike Dampier on 12/30/25.
//

import Foundation

struct Root: Decodable {
    let content: [ContentItem]
    let metadata: Metadata?
    let role: String?
    let schema_version: String?
}

struct Metadata: Decodable {
    let usage: Usage?
}

struct Usage: Decodable {
    let tokens_consumed: [TokenConsumption]?
}

struct TokenConsumption: Decodable {
    let context_window: Int?
    let input_tokens: TokenDetail?
    let model_name: String?
    let output_tokens: TokenOutput?
}

struct TokenDetail: Decodable {
    let cache_read: Int?
    let cache_write: Int?
    let total: Int?
    let uncached: Int?
}

struct TokenOutput: Decodable {
    let total: Int?
}

// The items inside "content" are heterogeneous; use an enum keyed by "type"
enum ContentItem: Decodable {
    case thinking(ThinkingItem)
    case toolUse(ToolUseItem)
    case toolResult(ToolResultItem)
    case text(TextItem)
    case unknown(RawContent) // fallback if an unexpected type appears

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // If "type" is missing, try to decode as RawContent and treat as unknown
        let type = (try? container.decode(String.self, forKey: .type)) ?? "unknown"

        let single = try RawContent(from: decoder) // decode the whole object first (for flexibility)

        switch type {
        case "thinking":
            let value = try ThinkingItem(from: decoder)
            self = .thinking(value)
        case "tool_use":
            let value = try ToolUseItem(from: decoder)
            self = .toolUse(value)
        case "tool_result":
            let value = try ToolResultItem(from: decoder)
            self = .toolResult(value)
        case "text":
            let value = try TextItem(from: decoder)
            self = .text(value)
        default:
            self = .unknown(single)
        }
    }
}

// A raw, catch-all model so we can keep unknown fields when necessary
struct RawContent: Decodable {
    let type: String?
    // Keep the rest as a dictionary for debugging/inspection if needed
    let raw: [String: AnyDecodable]

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var dict: [String: AnyDecodable] = [:]
        var typeValue: String? = nil

        for key in container.allKeys {
            if key.stringValue == "type" {
                typeValue = try container.decodeIfPresent(String.self, forKey: key)
            }
            dict[key.stringValue] = try container.decode(AnyDecodable.self, forKey: key)
        }
        self.type = typeValue
        self.raw = dict
    }
}

// Concrete item types
struct ThinkingItem: Decodable {
    let type: String
    let thinking: ThinkingContent

    struct ThinkingContent: Decodable {
        let text: String
    }
}

struct ToolUseItem: Decodable {
    let type: String
    let tool_use: ToolUse

    struct ToolUse: Decodable {
        let client_side_execute: Bool?
        let input: ToolInput?
        let name: String?
        let tool_use_id: String?
        let type: String?
    }

    struct ToolInput: Decodable {
        let has_time_column: Bool?
        let need_future_forecasting_data: Bool?
        let original_query: String?
        let previous_related_tool_result_id: String?
        let query: String?
    }
}

struct ToolResultItem: Decodable {
    let type: String
    let tool_result: ToolResult

    struct ToolResult: Decodable {
        let content: [ToolContent]?
        let name: String?
        let status: String?
        let tool_use_id: String?
        let type: String?
    }

    struct ToolContent: Decodable {
        // In your sample, this is like:
        // { "json": { ... }, "type": "json" }
        let json: ToolJSONPayload?
        let type: String?
    }

    struct ToolJSONPayload: Decodable {
        let query_id: String?
        let result_set: ResultSet?
        let statementHandle: String?
        let sql: String?
        let text: String?
    }

    struct ResultSet: Decodable {
        let data: [[String]]?
        let resultSetMetaData: ResultSetMetaData?
    }

    struct ResultSetMetaData: Decodable {
        let format: String?
        let numRows: Int?
        let partition: Int?
        let rowType: [RowType]?
    }

    struct RowType: Decodable {
        let length: Int?
        let name: String?
        let nullable: Bool?
        let precision: Int?
        let scale: Int?
        let type: String?
    }
}

struct TextItem: Decodable {
    let type: String
    let text: String
}

// A lightweight type-erased Decodable to hold arbitrary JSON
struct AnyDecodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if container.decodeNil() {
                self.value = NSNull()
            } else if let b = try? container.decode(Bool.self) {
                self.value = b
            } else if let i = try? container.decode(Int.self) {
                self.value = i
            } else if let d = try? container.decode(Double.self) {
                self.value = d
            } else if let s = try? container.decode(String.self) {
                self.value = s
            } else if let arr = try? container.decode([AnyDecodable].self) {
                self.value = arr.map { $0.value }
            } else if let dict = try? container.decode([String: AnyDecodable].self) {
                self.value = dict.mapValues { $0.value }
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
            }
        } else {
            self.value = NSNull()
        }
    }
}

func decodeRoot(from raw: String) throws -> Root {
    // Find the first “{” to skip any leading “data: ” or other non-JSON prefixes
    guard let startIndex = raw.firstIndex(of: "{") else {
        throw NSError(domain: "Decoder", code: 1, userInfo: [NSLocalizedDescriptionKey: "No JSON object found"])
    }
    let jsonSubstring = raw[startIndex...]
    let jsonData = Data(jsonSubstring.utf8)

    let decoder = JSONDecoder()
    return try decoder.decode(Root.self, from: jsonData)
}
 
func parseFinalResults(json: String) -> String {
    var returnText = "No data"
    do {
        let root = try decodeRoot(from: json)
        if let finalText = root.content.compactMap({ item -> String? in
            if case let .text(textItem) = item { return textItem.text }
            return nil
        }).last {
            returnText = finalText
        }
        if let toolPayload = root.content.compactMap({ item -> ToolResultItem.ToolJSONPayload? in
            if case let .toolResult(tr) = item {
                return tr.tool_result.content?.first?.json
            }
            return nil
        }).first,
           let rows = toolPayload.result_set?.data,
           let firstRow = rows.first {
           //print("\(firstRow.first ?? "N/A")")
        }
    } catch {
        print("Decoding failed: \(error)")
    }
    return returnText
}

