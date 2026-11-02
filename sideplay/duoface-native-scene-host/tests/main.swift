//  Decoder172HostTests.swift
//  DuoFace — QA172 gate G2 host tests for DFGofaPayloadDecoder172.
//
//  Standalone harness (no XCTest) so it runs with a bare swiftc on
//  any host:  swiftc DFGofaPayloadDecoder172.swift \
//                    tests/main.swift -o decoder-tests
//  Exit code 0 = all checks passed.
//
//  Synthetic stand-in models only — no GOFA code, no vendor shapes
//  beyond the interface facts in FIELD_MAP.md (key names, ranges).

import Foundation

var failures = 0
var checks = 0
func check(_ condition: Bool, _ name: String) {
    checks += 1
    if !condition {
        failures += 1
        print("FAIL: \(name)")
    } else {
        print("pass: \(name)")
    }
}
func approx(_ a: Double?, _ b: Double) -> Bool {
    guard let a = a else { return false }
    return abs(a - b) < 0.0001
}

typealias D = DFGofaPayloadDecoder172

// MARK: - Synthetic models

final class SpeedBoardModel {
    var userSpeed: Double = 54
    var speed: NSNumber = 55
    var currentAllowSpeed: Int = 60
    var limit: Double = 60
}

class BaseBoard {
    var limit: Double = 50
}
final class ChildBoard: BaseBoard {
    var userSpeed: Float = 41.5
}

final class StringyBoard {
    var userSpeed: String = "54"     // wrong type on purpose
    var speed: Double = 9999         // out of range on purpose
    var currentAllowSpeed: Double = .nan
    var limit: Double = 0            // not a valid limit
}

final class DatapointModel {
    var traffic_sign_id: Int = 42
    var lat: Double = 10.762622
    var lon: Double = 106.660172
    init(id: Int = 42, lat: Double = 10.762622, lon: Double = 106.660172) {
        self.traffic_sign_id = id
        self.lat = lat
        self.lon = lon
    }
}

final class FakeGOFABoard {
    var speed: Double = 33
}

// MARK: - Speed channel

// 1. Full board from a Swift model object (Mirror path).
if let b = D.decodeSpeedBoard(userInfo: ["pushSpeedBoard": SpeedBoardModel()]) {
    check(approx(b.userSpeed, 54), "model userSpeed")
    check(approx(b.speed, 55), "model speed (NSNumber)")
    check(approx(b.currentAllowSpeed, 60), "model currentAllowSpeed (Int)")
    check(approx(b.limit, 60), "model limit")
    check(b.diagnostics.fieldsPresent == 0b1111, "model present mask")
    check(b.diagnostics.fieldsRejected == 0, "model rejected mask empty")
    check(b.diagnostics.valueKind == .other, "model kind = other")
    check(b.diagnostics.valueTypeName.contains("SpeedBoardModel"),
          "model type name reported")
} else { check(false, "model board decodes") }

// 2. Dictionary payload path.
if let b = D.decodeSpeedBoard(userInfo: [
    "pushSpeedBoard": ["userSpeed": 10.0, "speed": 11.0,
                       "currentAllowSpeed": 30.0, "limit": 30.0]]) {
    check(b.diagnostics.valueKind == .dictionary, "dict kind")
    check(b.diagnostics.fieldsPresent == 0b1111, "dict present mask")
    check(approx(b.limit, 30), "dict limit")
} else { check(false, "dict board decodes") }

// 3. Missing keys -> only the present field is set.
if let b = D.decodeSpeedBoard(userInfo: [
    "pushSpeedBoard": ["limit": 80.0]]) {
    check(b.userSpeed == nil && b.speed == nil &&
          b.currentAllowSpeed == nil, "missing keys stay nil")
    check(approx(b.limit, 80), "only limit set")
    check(b.diagnostics.fieldsPresent == 0b1000, "only limit mask bit")
    check(b.hasAnyField, "hasAnyField with limit only")
} else { check(false, "sparse board decodes") }

// 4. Payload key absent -> nil board (nothing to decode).
check(D.decodeSpeedBoard(userInfo: ["unrelated": 1]) == nil,
      "absent payload key -> nil")

// 5. Wrong types and out-of-range values are rejected per-field.
if let b = D.decodeSpeedBoard(userInfo: ["pushSpeedBoard": StringyBoard()]) {
    check(b.userSpeed == nil && b.speed == nil &&
          b.currentAllowSpeed == nil && b.limit == nil,
          "all bad fields nil")
    check(b.diagnostics.fieldsRejected == 0b1111, "all bad fields rejected")
    check(b.diagnostics.fieldsPresent == 0, "no bad field presented")
    check(!b.hasAnyField, "hasAnyField false when all rejected")
} else { check(false, "bad board still returns diagnostics") }

// 6. Boundary values: limit 200 ok, 201 rejected; speed 400 ok, 401 no.
if let b = D.decodeSpeedBoard(userInfo: [
    "pushSpeedBoard": ["speed": 400.0, "limit": 200.0]]) {
    check(b.diagnostics.fieldsPresent == 0b1010, "boundary values accepted")
} else { check(false, "boundary board decodes") }
if let b = D.decodeSpeedBoard(userInfo: [
    "pushSpeedBoard": ["speed": 401.0, "limit": 201.0]]) {
    check(b.diagnostics.fieldsRejected == 0b1010, "over-boundary rejected")
} else { check(false, "over-boundary board decodes") }

// 7. Superclass stored properties are found via superclassMirror.
if let b = D.decodeSpeedBoard(userInfo: ["pushSpeedBoard": ChildBoard()]) {
    check(approx(b.limit, 50), "superclass limit found")
    check(approx(b.userSpeed, 41.5), "Float userSpeed coerced")
} else { check(false, "child board decodes") }

// 8. Type name containing GOFA classifies as gofaObject (log-only).
if let b = D.decodeSpeedBoard(userInfo: ["pushSpeedBoard": FakeGOFABoard()]) {
    check(b.diagnostics.valueKind == .gofaObject, "GOFA-named kind")
    check(approx(b.speed, 33), "GOFA-named board still decodes")
} else { check(false, "GOFA-named board decodes") }

// MARK: - Alert channel

// 9. Array of point models (Mirror per element).
let three = [DatapointModel(id: 1), DatapointModel(id: 2),
             DatapointModel(id: 3)]
let (pts, diag) = D.decodeAlertPoints(
    notificationName: "notificationNextBoard",
    userInfo: ["pushNextBoard": three])
check(pts.count == 3, "three points accepted")
check(diag.pointsAccepted == 3 && diag.pointsRejected == 0,
      "alert counters clean")
check(pts.first?.sign == "1", "traffic_sign_id normalised to sign")
check(approx(pts.first?.latitude, 10.762622), "point latitude")
check(diag.valueKind == .array, "alert value kind = array")

// 10. The Other board reads its own key, not the Next key.
let (nonePts, _) = D.decodeAlertPoints(
    notificationName: "notificationNextBoard",
    userInfo: ["pushOtherBoardToCarplay": three])
check(nonePts.isEmpty, "next board ignores other key")
let (otherPts, _) = D.decodeAlertPoints(
    notificationName: "notificationOtherBoard",
    userInfo: ["pushOtherBoardToCarplay": three])
check(otherPts.count == 3, "other board reads its key")

// 11. Bad coordinates are rejected point-by-point.
let mixed: [Any] = [DatapointModel(id: 1),
                    DatapointModel(id: 2, lat: 91),
                    DatapointModel(id: 3, lon: -181),
                    ["traffic_sign_id": "cam"] as [String: Any]]
let (mixedPts, mixedDiag) = D.decodeAlertPoints(
    notificationName: "notificationNextBoard",
    userInfo: ["pushNextBoard": mixed])
check(mixedPts.count == 1, "only the valid model point survives")
check(mixedDiag.pointsRejected == 3,
      "bad lat, bad lon and coord-less dict all rejected")

// 12. Dictionary points with string sign decode fully.
let dictPoints: [[String: Any]] = [
    ["traffic_sign_id": "speedcam", "lat": 10.0, "lon": 106.0,
     "identity": "p1"]]
let (dPts, _) = D.decodeAlertPoints(
    notificationName: "notificationNextBoard",
    userInfo: ["pushNextBoard": dictPoints])
check(dPts.count == 1 && dPts.first?.sign == "speedcam" &&
      dPts.first?.identity == "p1", "dictionary point decodes")

// 13. Oversized arrays are capped at 32 accepted points.
let forty = (0..<40).map { DatapointModel(id: $0) }
let (capped, capDiag) = D.decodeAlertPoints(
    notificationName: "notificationNextBoard",
    userInfo: ["pushNextBoard": forty])
check(capped.count == 32, "points capped at 32")
check(capDiag.pointsAccepted == 32, "cap visible in counters")

// 14. Missing payload key -> empty, no crash, kind none.
let (emptyPts, emptyDiag) = D.decodeAlertPoints(
    notificationName: "notificationNextBoard", userInfo: [:])
check(emptyPts.isEmpty && emptyDiag.valueKind == .none,
      "missing alert key -> empty + kind none")

print("----")
print("\(checks - failures)/\(checks) checks passed")
exit(failures == 0 ? 0 : 1)
