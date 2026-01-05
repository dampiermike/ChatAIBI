//
//  ParseChart.swift
//  ChatAIBI
//
//  Created by Mike Dampier on 1/7/26.
//

import Foundation
/// Minimal structures required to build a Swift Chart from the incoming payload.
public struct ChartDatum: Identifiable, Equatable {
    public let id = UUID()
    // Backward-compatible fields used by bar/line/arc
    public let category: String
    public let value: Double
    // Additional fields for scatter/circle charts
    public let xValue: Double?
    public let yValue: Double?
    public let size: Double?
    public let colorCategory: String?

    public init(category: String, value: Double, xValue: Double? = nil, yValue: Double? = nil, size: Double? = nil, colorCategory: String? = nil) {
        self.category = category
        self.value = value
        self.xValue = xValue
        self.yValue = yValue
        self.size = size
        self.colorCategory = colorCategory
    }
}

public struct ChartSpec: Equatable {
    public let title: String?
    public let mark: String?
    public let xField: String?
    public let xTitle: String?
    public let yField: String?
    public let yTitle: String?
    public let data: [ChartDatum]
}

/// Top-level payload coming from the tool output.
/// Example: { "chart_spec": "{ ...json string... }", ... }
private struct ToolPayload: Decodable {
    let chart_spec: String
}

/// Inner chart spec (Vega-Lite-like) as embedded JSON string.
private struct EmbeddedChartSpec: Decodable {
    let title: String?
    let mark: String?
    let encoding: Encoding?
    let data: ValuesContainer?

    struct Encoding: Decodable {
        let x: AxisSpec?
        let y: AxisSpec?
        let theta: AxisSpec?
        let color: AxisSpec?
        let size: AxisSpec?

        struct AxisSpec: Decodable {
            let field: String?
            let title: String?
            let type: String?
        }
    }

    struct ValuesContainer: Decodable {
        let values: [[String: CodableValue]]
    }
}

/// A helper to decode arbitrary JSON leaf values (String, Double, Int, Bool, null)
private enum CodableValue: Decodable {
    case string(String)
    case double(Double)
    case int(Int)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else {
            // Unsupported nested structure for our purposes
            self = .null
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .double(let d): return String(d)
        case .int(let i): return String(i)
        case .bool(let b): return String(b)
        case .null: return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .double(let d): return d
        case .int(let i): return Double(i)
        case .string(let s): return Double(s)
        case .bool(let b): return b ? 1.0 : 0.0
        case .null: return nil
        }
    }
}

public enum ChartParseError: Error {
    case invalidUTF8
    case topLevelDecodingFailed
    case embeddedSpecDecodingFailed
}

/// Parses the incoming JSON `Data` and returns a simplified `ChartSpec` suitable for Swift Charts.
public func parseChartSpec(from jsonData: Data) throws -> ChartSpec {
    // 1) Decode the top-level wrapper to get the embedded chart_spec string.
    let decoder = JSONDecoder()
    let payload: ToolPayload
    do {
        payload = try decoder.decode(ToolPayload.self, from: jsonData)
    } catch {
        throw ChartParseError.topLevelDecodingFailed
    }

    // 2) The chart_spec itself is a JSON string. Decode it into the embedded model.
    guard let specData = payload.chart_spec.data(using: .utf8) else {
        throw ChartParseError.invalidUTF8
    }

    let embedded: EmbeddedChartSpec
    do {
        embedded = try decoder.decode(EmbeddedChartSpec.self, from: specData)
    } catch {
        throw ChartParseError.embeddedSpecDecodingFailed
    }

    let xField = embedded.encoding?.x?.field
    let xTitle = embedded.encoding?.x?.title
    let yField = embedded.encoding?.y?.field
    let yTitle = embedded.encoding?.y?.title

    let xType = embedded.encoding?.x?.type
    let yType = embedded.encoding?.y?.type

    let thetaField = embedded.encoding?.theta?.field
    //let thetaType = embedded.encoding?.theta?.type
    let colorField = embedded.encoding?.color?.field
    let sizeField = embedded.encoding?.size?.field

    let rows = embedded.data?.values ?? []

    // Date parsing helper for common ISO date strings
    let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "LLL" // e.g., Jan, Feb
        return f
    }()

    let data: [ChartDatum] = rows.compactMap { row in
        // Helper to produce a string label from a CodableValue, with date-to-month formatting when possible
        func label(from value: CodableValue) -> String {
            if let s = value.stringValue {
                if let date = isoFormatter.date(from: s) {
                    return monthFormatter.string(from: date)
                }
                return s
            }
            return ""
        }

        // 1) Arc/Pie support: if theta is present or mark == "arc", map theta as value and choose a category label from color/x/y in that order
        if embedded.mark == "arc" || thetaField != nil {
            if let tKey = thetaField, let tRaw = row[tKey], let numeric = tRaw.doubleValue {
                // Prefer color field for category, else fall back to x, then y, else empty
                if let cKey = colorField, let cRaw = row[cKey] {
                    return ChartDatum(category: label(from: cRaw), value: numeric)
                } else if let xKey = xField, let xRaw = row[xKey] {
                    return ChartDatum(category: label(from: xRaw), value: numeric)
                } else if let yKey = yField, let yRaw = row[yKey] {
                    return ChartDatum(category: label(from: yRaw), value: numeric)
                } else {
                    return ChartDatum(category: "", value: numeric)
                }
            }
            return nil
        }

        // 2) Circle/Scatter (with optional bubble size) support
        if embedded.mark == "circle" {
            guard let xKey = xField, let yKey = yField,
                  let xRaw = row[xKey], let yRaw = row[yKey],
                  let xNum = xRaw.doubleValue, let yNum = yRaw.doubleValue else { return nil }

            let sizeNum: Double?
            if let sKey = sizeField, let sRaw = row[sKey] { sizeNum = sRaw.doubleValue } else { sizeNum = nil }

            // Color category label if provided; otherwise empty
            let colorLabel: String?
            if let cKey = colorField, let cRaw = row[cKey] { colorLabel = label(from: cRaw) } else { colorLabel = nil }

            // For backward compatibility, set category/value to sensible defaults for charts that don't use them
            // Use x as category string and y as value by default
            let categoryLabel = label(from: xRaw)
            let valueForCompat = yNum

            return ChartDatum(
                category: categoryLabel,
                value: valueForCompat,
                xValue: xNum,
                yValue: yNum,
                size: sizeNum,
                colorCategory: colorLabel
            )
        }

        // 3) Standard x/y routing
        guard let xKey = xField, let yKey = yField,
              let xRaw = row[xKey], let yRaw = row[yKey] else { return nil }

        if xType == "quantitative", let numeric = xRaw.doubleValue {
            // Value on x, category on y
            let categoryLabel = label(from: yRaw)
            return ChartDatum(category: categoryLabel, value: numeric)
        } else if yType == "quantitative", let numeric = yRaw.doubleValue {
            // Value on y, category on x
            let categoryLabel = label(from: xRaw)
            return ChartDatum(category: categoryLabel, value: numeric)
        } else {
            // Fallbacks: try y as numeric, else x as numeric
            if let numeric = yRaw.doubleValue {
                let categoryLabel = label(from: xRaw)
                return ChartDatum(category: categoryLabel, value: numeric)
            } else if let numeric = xRaw.doubleValue {
                let categoryLabel = label(from: yRaw)
                return ChartDatum(category: categoryLabel, value: numeric)
            } else {
                return nil
            }
        }
    }

    return ChartSpec(
        title: embedded.title,
        mark: embedded.mark,
        xField: xField,
        xTitle: xTitle,
        yField: yField,
        yTitle: yTitle,
        data: data
    )
}

/// Convenience for testing with a String sample.
public func parseChartSpec(from jsonString: String) throws -> ChartSpec {
    guard let data = jsonString.data(using: .utf8) else { throw ChartParseError.invalidUTF8 }
    return try parseChartSpec(from: data)
}

