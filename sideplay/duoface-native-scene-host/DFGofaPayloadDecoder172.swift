//  DFGofaPayloadDecoder172.swift
//  DuoFace — QA172 clean-room GOFA payload decoder (first-party code).
//
//  Written from the interface specification in
//  sideplay/audit/qa172-gofa-payload-decoder-20261102/FIELD_MAP.md:
//  externally observable facts only (notification names, userInfo keys,
//  value shapes). No vendor code is copied or referenced; the extraction
//  technique is the public Swift `Mirror` reflection facility, bounded
//  and structurally validated.
//
//  The decoder observes nothing by itself. An Objective-C observer glue
//  (DFGofaBoardSource172, gate G3) hands it the userInfo dictionary of
//  the three GOFA board notifications received inside the GOFA process:
//
//    notificationSpeedBoard  -> userInfo["pushSpeedBoard"]
//    notificationNextBoard   -> userInfo["pushNextBoard"]
//    notificationOtherBoard  -> userInfo["pushOtherBoardToCarplay"]
//
//  Design rules (DESIGN.md, non-negotiable):
//   - Structural validation only. Payload type names are reported as
//     diagnostics, never required — the decoder survives GOFA renames.
//   - Bounded reflection: children <= 64 per object, points <= 32.
//   - Malformed or out-of-range data is dropped and counted, never
//     fabricated and never crashing the host (GOFA) process.
//   - Both `userSpeed` and `speed` are carried, labelled (FIELD_MAP §5:
//     display semantics are a device-observation question, not a guess).
//   - Diagnostics contain type names and counters only — never
//     coordinates, route data or payload values (QA166/167 rules).
//
//  Pure Swift + Foundation. Host-testable with synthetic models.

import Foundation

public enum DFGofaPayloadDecoder172 {

    // MARK: - Public types

    /// Kind codes intentionally match DF167GOFAEventProtocol so the
    /// existing evidence tooling reads both generations the same way.
    public enum ValueKind: Int {
        case none = 0
        case dictionary = 1
        case array = 2
        case gofaObject = 3
        case other = 4
    }

    /// Sanitised facts about one decode attempt. Safe to log/transport:
    /// names, kinds and counters only.
    public struct Diagnostics {
        /// `String(reflecting:)` of the payload value, e.g.
        /// "GOFA.SpeedBoardModel" — evidence, never a requirement.
        public var valueTypeName: String = ""
        public var valueKind: ValueKind = .none
        /// Speed channels, bit0 userSpeed, bit1 speed,
        /// bit2 currentAllowSpeed, bit3 limit: present-and-valid.
        public var fieldsPresent: UInt8 = 0
        /// Same bit layout: present but rejected (type/range).
        public var fieldsRejected: UInt8 = 0
        /// Alert channel: accepted / rejected point counters.
        public var pointsAccepted: Int = 0
        public var pointsRejected: Int = 0
        public init() {}
    }

    /// Normalised speed board. Every field optional: a missing limit
    /// stays missing ("—" on the HUD), it is never invented.
    public struct SpeedBoard {
        public var userSpeed: Double?
        public var speed: Double?
        public var currentAllowSpeed: Double?
        public var limit: Double?
        public var diagnostics: Diagnostics
        public var hasAnyField: Bool {
            userSpeed != nil || speed != nil ||
            currentAllowSpeed != nil || limit != nil
        }
    }

    /// Normalised alert point (FIELD_MAP §3 output shape).
    public struct AlertPoint {
        public var identity: String?
        public var sign: String?
        public var latitude: Double
        public var longitude: Double
    }

    // MARK: - Constants (validation mirrors DFSpeedProtocol.hpp)

    static let maxChildren = 64
    static let maxPoints = 32
    static let maxSpeedKmh = 400.0
    static let maxLimitKmh = 200.0

    public static let speedBoardKey = "pushSpeedBoard"
    public static let nextBoardKey = "pushNextBoard"
    public static let otherBoardKey = "pushOtherBoardToCarplay"

    // MARK: - Speed channel

    /// Decode the speed board carried by a `notificationSpeedBoard`
    /// userInfo dictionary. Returns nil only when the payload key is
    /// absent entirely; a present-but-unusable payload yields a board
    /// with no valid fields plus diagnostics saying why.
    public static func decodeSpeedBoard(userInfo: [AnyHashable: Any]) -> SpeedBoard? {
        guard let raw = userInfo[speedBoardKey] else { return nil }
        var diag = Diagnostics()
        diag.valueTypeName = String(reflecting: type(of: raw))
        diag.valueKind = kind(of: raw)
        let fields = labelledFields(of: raw)
        let userSpeed = speedField(fields, key: "userSpeed", bit: 0,
                                   diag: &diag)
        let speed = speedField(fields, key: "speed", bit: 1, diag: &diag)
        let allow = speedField(fields, key: "currentAllowSpeed", bit: 2,
                               diag: &diag)
        let limit = limitField(fields, key: "limit", bit: 3, diag: &diag)
        return SpeedBoard(userSpeed: userSpeed, speed: speed,
                          currentAllowSpeed: allow, limit: limit,
                          diagnostics: diag)
    }

    // MARK: - Alert channel

    /// Decode the alert points carried by a `notificationNextBoard`
    /// (key `pushNextBoard`) or `notificationOtherBoard`
    /// (key `pushOtherBoardToCarplay`) userInfo dictionary.
    public static func decodeAlertPoints(notificationName: String,
                                         userInfo: [AnyHashable: Any])
        -> (points: [AlertPoint], diagnostics: Diagnostics) {
        var diag = Diagnostics()
        let key = (notificationName == "notificationNextBoard")
            ? nextBoardKey : otherBoardKey
        guard let raw = userInfo[key] else { return ([], diag) }
        diag.valueTypeName = String(reflecting: type(of: raw))
        diag.valueKind = kind(of: raw)
        let elements = arrayElements(of: raw)
        var points: [AlertPoint] = []
        for element in elements {
            if points.count >= maxPoints { break }
            if let point = alertPoint(from: element) {
                points.append(point)
                diag.pointsAccepted += 1
            } else {
                diag.pointsRejected += 1
            }
        }
        // Elements beyond the cap are neither accepted nor inspected;
        // the accepted counter makes truncation visible in diagnostics.
        return (points, diag)
    }

    // MARK: - Reflection core

    /// Convert a payload value into a labelled field dictionary.
    /// Dictionaries pass through (keys stringified); model objects are
    /// read with `Mirror` over their stored properties (own class first,
    /// then superclass mirrors), bounded at `maxChildren` labels.
    /// Mirrors the *shape* of the original route's conversion without
    /// copying any of its code.
    static func labelledFields(of value: Any) -> [String: Any] {
        if let dict = value as? [String: Any] { return dict }
        if let dict = value as? NSDictionary {
            var out: [String: Any] = [:]
            for key in dict.allKeys {
                if let name = key as? String { out[name] = dict[key] }
            }
            return out
        }
        var out: [String: Any] = [:]
        var seen = 0
        var current: Mirror? = Mirror(reflecting: value)
        while let m = current, seen < maxChildren {
            for child in m.children {
                if seen >= maxChildren { break }
                seen += 1
                guard let label = child.label, out[label] == nil else {
                    continue
                }
                out[label] = child.value
            }
            current = m.superclassMirror
        }
        return out
    }

    static func arrayElements(of value: Any) -> [Any] {
        if let array = value as? [Any] { return array }
        if let array = value as? NSArray {
            return array.compactMap { $0 }
        }
        // A Swift array that did not bridge cleanly: Mirror exposes
        // its elements as unlabelled children.
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .collection {
            return mirror.children.map { $0.value }
        }
        return []
    }

    // MARK: - Field extraction

    private static func speedField(_ fields: [String: Any], key: String,
                                   bit: UInt8, diag: inout Diagnostics)
        -> Double? {
        guard let raw = fields[key] else { return nil }
        if let value = numeric(raw), value.isFinite,
           value >= 0, value <= maxSpeedKmh {
            diag.fieldsPresent |= (1 << bit)
            return value
        }
        diag.fieldsRejected |= (1 << bit)
        return nil
    }

    private static func limitField(_ fields: [String: Any], key: String,
                                   bit: UInt8, diag: inout Diagnostics)
        -> Double? {
        guard let raw = fields[key] else { return nil }
        if let value = numeric(raw), value.isFinite,
           value > 0, value <= maxLimitKmh {
            diag.fieldsPresent |= (1 << bit)
            return value
        }
        diag.fieldsRejected |= (1 << bit)
        return nil
    }

    private static func alertPoint(from element: Any) -> AlertPoint? {
        let fields = labelledFields(of: element)
        guard let latRaw = fields["lat"] ?? fields["latitude"],
              let lonRaw = fields["lon"] ?? fields["longitude"],
              let lat = numeric(latRaw), lat.isFinite,
              lat >= -90, lat <= 90,
              let lon = numeric(lonRaw), lon.isFinite,
              lon >= -180, lon <= 180 else {
            return nil
        }
        return AlertPoint(
            identity: stringValue(fields["identity"]),
            sign: stringValue(fields["traffic_sign_id"] ?? fields["sign"]),
            latitude: lat,
            longitude: lon)
    }

    // MARK: - Scalar coercion

    /// Accept the numeric representations a Swift model or an
    /// NSDictionary can plausibly carry. Strings are NOT numbers here:
    /// a stringly-typed field is a shape change and must be rejected,
    /// not parsed into a fabricated value.
    static func numeric(_ value: Any) -> Double? {
        switch value {
        case let n as NSNumber: return n.doubleValue
        case let d as Double: return d
        case let f as Float: return Double(f)
        case let i as Int: return Double(i)
        case let i as Int64: return Double(i)
        case let i as Int32: return Double(i)
        case let u as UInt: return Double(u)
        case let u as UInt64: return Double(u)
        default: return nil
        }
    }

    static func stringValue(_ value: Any?) -> String? {
        guard let value = value else { return nil }
        if let s = value as? String { return s }
        if let n = value as? NSNumber { return n.stringValue }
        return nil
    }

    static func kind(of value: Any) -> ValueKind {
        if value is [String: Any] || value is NSDictionary {
            return .dictionary
        }
        if value is [Any] || value is NSArray { return .array }
        let name = String(reflecting: type(of: value))
        if name.contains("GOFA") { return .gofaObject }
        return .other
    }
}

#if canImport(ObjectiveC)
// MARK: - Objective-C bridge (compiled on iOS only)
//
// Thin @objc wrapper so the C/ObjC observer glue consumes plain
// dictionaries and counters. Declared in DFGofaPayloadDecoder172.h.

@objc(DFGofaDecoder172)
public final class DFGofaDecoder172Bridge: NSObject {
    /// Returns the normalised board as an NSDictionary with the found
    /// subset of {userSpeed, speed, currentAllowSpeed, limit} plus a
    /// "diagnostics" entry (type name, kind, present/rejected masks),
    /// or nil when the payload key is absent.
    @objc public static func decodeSpeedBoard(
        userInfo: [AnyHashable: Any]) -> NSDictionary? {
        guard let board = DFGofaPayloadDecoder172.decodeSpeedBoard(
            userInfo: userInfo) else { return nil }
        let out = NSMutableDictionary()
        if let v = board.userSpeed { out["userSpeed"] = v }
        if let v = board.speed { out["speed"] = v }
        if let v = board.currentAllowSpeed {
            out["currentAllowSpeed"] = v
        }
        if let v = board.limit { out["limit"] = v }
        out["diagnostics"] = [
            "valueTypeName": board.diagnostics.valueTypeName,
            "valueKind": board.diagnostics.valueKind.rawValue,
            "fieldsPresent": Int(board.diagnostics.fieldsPresent),
            "fieldsRejected": Int(board.diagnostics.fieldsRejected),
        ]
        return out
    }

    /// Returns an NSArray of point dictionaries
    /// {identity?, sign?, latitude, longitude} plus diagnostics via
    /// the same "diagnostics" convention on a wrapper dictionary:
    /// {points: [...], diagnostics: {...}}.
    @objc public static func decodeAlertPoints(
        notificationName: String,
        userInfo: [AnyHashable: Any]) -> NSDictionary {
        let (points, diag) = DFGofaPayloadDecoder172.decodeAlertPoints(
            notificationName: notificationName, userInfo: userInfo)
        let list = NSMutableArray()
        for point in points {
            let entry = NSMutableDictionary()
            if let v = point.identity { entry["identity"] = v }
            if let v = point.sign { entry["sign"] = v }
            entry["latitude"] = point.latitude
            entry["longitude"] = point.longitude
            list.add(entry)
        }
        return [
            "points": list,
            "diagnostics": [
                "valueTypeName": diag.valueTypeName,
                "valueKind": diag.valueKind.rawValue,
                "pointsAccepted": diag.pointsAccepted,
                "pointsRejected": diag.pointsRejected,
            ],
        ]
    }
}
#endif
