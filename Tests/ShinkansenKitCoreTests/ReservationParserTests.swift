import Foundation
import Testing
@testable import ShinkansenKitCore

private struct FixtureInput {
    let title: String
    let location: String
    let notes: String
}

private func loadFixture(_ name: String) throws -> FixtureInput {
    guard let url = Bundle.module.url(forResource: name, withExtension: "txt") else {
        throw FixtureError.notFound(name)
    }
    let raw = try String(contentsOf: url, encoding: .utf8)
    let lines = raw.components(separatedBy: "\n")
    var title = ""
    var location = ""
    var notesLines: [String] = []
    var section = ""
    for line in lines {
        if line.hasPrefix("//") { continue }
        switch line {
        case "---TITLE---":
            section = "title"
        case "---LOCATION---":
            section = "location"
        case "---NOTES---":
            section = "notes"
        default:
            switch section {
            case "title": if title.isEmpty { title = line }
            case "location": if location.isEmpty { location = line }
            case "notes": notesLines.append(line)
            default: break
            }
        }
    }
    while notesLines.last?.isEmpty == true { notesLines.removeLast() }
    return FixtureInput(title: title, location: location, notes: notesLines.joined(separator: "\n"))
}

private enum FixtureError: Error {
    case notFound(String)
}

private func jstDate(_ y: Int, _ m: Int, _ d: Int, _ hh: Int = 0, _ mm: Int = 0) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d; c.hour = hh; c.minute = mm
    return cal.date(from: c)!
}

@Test func parsesNonReserved() throws {
    let f = try loadFixture("non_reserved")
    let r = try #require(ReservationParser().parse(title: f.title, location: f.location, notes: f.notes))
    #expect(r.kind == nil)
    #expect(r.trainNumber == nil)
    #expect(r.departureStation == "東京")
    #expect(r.arrivalStation == "新大阪")
    #expect(r.boardingDate == jstDate(2099, 1, 15))
    #expect(r.departureTime == nil)
    #expect(r.arrivalTime == nil)
    #expect(r.seatClass == .nonReserved)
    #expect(r.carNumber == nil)
    #expect(r.seats.isEmpty)
    #expect(r.passengers.adults == 1)
    #expect(r.passengers.children == 0)
    #expect(r.product == "EX 予約（自由席）")
    #expect(r.formation == "N700系16両")
    #expect(r.smoking == nil)
}

@Test func parsesReservedMultiSeat() throws {
    let f = try loadFixture("reserved_multi_seat")
    let r = try #require(ReservationParser().parse(title: f.title, location: f.location, notes: f.notes))
    #expect(r.kind == .nozomi)
    #expect(r.trainNumber == 999)
    #expect(r.departureStation == "東京")
    #expect(r.arrivalStation == "博多")
    #expect(r.boardingDate == jstDate(2099, 2, 20))
    #expect(r.departureTime == jstDate(2099, 2, 20, 9, 0))
    #expect(r.arrivalTime == jstDate(2099, 2, 20, 14, 0))
    #expect(r.seatClass == .reservedOrdinary)
    #expect(r.carNumber == 5)
    #expect(r.seats == ["3D", "3E"])
    #expect(r.passengers.adults == 2)
    #expect(r.passengers.children == 0)
    #expect(r.product == "EX 予約")
    #expect(r.formation == "N700系16両, 全車指定席")
    #expect(r.smoking == false)
}

@Test func parsesReservedOrdinary() throws {
    let f = try loadFixture("reserved_ordinary")
    let r = try #require(ReservationParser().parse(title: f.title, location: f.location, notes: f.notes))
    #expect(r.kind == .nozomi)
    #expect(r.trainNumber == 901)
    #expect(r.departureStation == "名古屋")
    #expect(r.arrivalStation == "広島")
    #expect(r.boardingDate == jstDate(2099, 3, 5))
    #expect(r.departureTime == jstDate(2099, 3, 5, 10, 30))
    #expect(r.arrivalTime == jstDate(2099, 3, 5, 13, 15))
    #expect(r.seatClass == .reservedOrdinary)
    #expect(r.carNumber == 8)
    #expect(r.seats == ["12C"])
    #expect(r.passengers.adults == 1)
    #expect(r.product == "EX 早特7[普通車用]")
    #expect(r.formation == "N700S系16両")
}

@Test func parsesGreenCar() throws {
    let f = try loadFixture("green_car")
    let r = try #require(ReservationParser().parse(title: f.title, location: f.location, notes: f.notes))
    #expect(r.kind == .nozomi)
    #expect(r.trainNumber == 877)
    #expect(r.departureStation == "京都")
    #expect(r.arrivalStation == "東京")
    #expect(r.boardingDate == jstDate(2099, 4, 10))
    #expect(r.departureTime == jstDate(2099, 4, 10, 18, 0))
    #expect(r.arrivalTime == jstDate(2099, 4, 10, 20, 15))
    #expect(r.seatClass == .greenCar)
    #expect(r.carNumber == 9)
    #expect(r.seats == ["5A"])
    #expect(r.passengers.adults == 1)
    #expect(r.product == "EX 早特3[グリーン車用]")
    #expect(r.formation == "N700S系16両")
}
