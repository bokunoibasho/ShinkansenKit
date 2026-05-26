import Foundation

public struct ReservationParser: Sendable {
    public init() {}

    public func parse(title: String?, location: String?, notes: String?) -> Reservation? {
        guard let notes else { return nil }

        var boardingDate: Date?
        var depTimeStr: String?
        var arrTimeStr: String?
        var departureStation: String?
        var arrivalStation: String?
        var adults = 0
        var children = 0
        var product = ""
        var trainNameLine: String?
        var formation = ""
        var carNumber: Int?
        var seats: [String] = []
        var seatClass: Reservation.SeatClass = .nonReserved
        var seatClassFound = false
        var smoking: Bool?

        for raw in notes.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            if let v = stripPrefix(line, "乗車日：") ?? stripPrefix(line, "乗車日:") {
                boardingDate = Self.parseDate(v)
            } else if let v = stripPrefix(line, "時刻：") ?? stripPrefix(line, "時刻:") {
                let (d, a) = Self.parseTimeRange(v)
                depTimeStr = d
                arrTimeStr = a
            } else if let v = stripPrefix(line, "区間：") ?? stripPrefix(line, "区間:") {
                if departureStation == nil {
                    let (d, a) = Self.parseStationRange(v)
                    departureStation = d
                    arrivalStation = a
                }
            } else if let v = stripPrefix(line, "人数：") ?? stripPrefix(line, "人数:") {
                let (a, c) = Self.parsePassengers(v)
                adults = a
                children = c
            } else if let v = stripPrefix(line, "商品：") ?? stripPrefix(line, "商品:") {
                product = v
            } else if line == "自由席" {
                seatClass = .nonReserved
                seatClassFound = true
                trainNameLine = "自由席"
            } else if line == "グリーン車" {
                seatClass = .greenCar
                seatClassFound = true
            } else if line.hasPrefix("普通車") {
                seatClass = .reservedOrdinary
                seatClassFound = true
                if line.contains("禁煙") {
                    smoking = false
                } else if line.contains("喫煙") {
                    smoking = true
                }
            } else if line.hasPrefix("N700") {
                formation = line
            } else if let car = Self.parseCarNumber(line) {
                carNumber = car
            } else if let parsedSeats = Self.parseSeats(line) {
                seats = parsedSeats
            } else if Self.isTrainName(line) {
                trainNameLine = line
            }
        }

        if departureStation == nil, let location {
            let (d, a) = Self.parseStationRange(location)
            departureStation = d
            arrivalStation = a
        }

        var kind: Reservation.TrainKind?
        var trainNumber: Int?
        if let trainNameLine, trainNameLine != "自由席" {
            (kind, trainNumber) = Self.parseTrainKindAndNumber(trainNameLine)
        } else if let title {
            let head = title.components(separatedBy: " / ").first ?? title
            if head != "自由席" {
                (kind, trainNumber) = Self.parseTrainKindAndNumber(head)
            }
        }

        if !seatClassFound, let title, title.hasPrefix("自由席") {
            seatClass = .nonReserved
        }

        guard let boardingDate, let departureStation, let arrivalStation else {
            return nil
        }

        return Reservation(
            kind: kind,
            trainNumber: trainNumber,
            departureStation: departureStation,
            arrivalStation: arrivalStation,
            boardingDate: boardingDate,
            departureTime: Self.combine(date: boardingDate, time: depTimeStr),
            arrivalTime: Self.combine(date: boardingDate, time: arrTimeStr),
            seatClass: seatClass,
            carNumber: carNumber,
            seats: seats,
            passengers: .init(adults: adults, children: children),
            product: product,
            formation: formation,
            smoking: smoking
        )
    }

    private func stripPrefix(_ s: String, _ prefix: String) -> String? {
        guard s.hasPrefix(prefix) else { return nil }
        return String(s.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
    }

    private static var jstCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        return cal
    }

    static func parseDate(_ s: String) -> Date? {
        let parts = s.split(whereSeparator: { $0 == "/" || $0 == "-" })
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else {
            return nil
        }
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = d
        return jstCalendar.date(from: comps)
    }

    static func parseTimeRange(_ s: String) -> (String?, String?) {
        let normalized = s
            .replacingOccurrences(of: "→", with: "→")
            .replacingOccurrences(of: "->", with: "→")
        let parts = normalized.components(separatedBy: "→").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        return (nil, nil)
    }

    static func parseStationRange(_ s: String) -> (String?, String?) {
        let normalized = s
            .replacingOccurrences(of: "→", with: "→")
            .replacingOccurrences(of: "->", with: "→")
            .replacingOccurrences(of: "–", with: "→")
            .replacingOccurrences(of: "—", with: "→")
            .replacingOccurrences(of: "ー", with: "→")
            .replacingOccurrences(of: "-", with: "→")
        let parts = normalized.components(separatedBy: "→").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        return (nil, nil)
    }

    static func parsePassengers(_ s: String) -> (Int, Int) {
        var adults = 0
        var children = 0
        let scanner = Scanner(string: s)
        scanner.charactersToBeSkipped = .whitespaces
        while !scanner.isAtEnd {
            if scanner.scanString("おとな") != nil {
                if let n = scanner.scanInt() {
                    adults = n
                    _ = scanner.scanString("名")
                }
            } else if scanner.scanString("こども") != nil {
                if let n = scanner.scanInt() {
                    children = n
                    _ = scanner.scanString("名")
                }
            } else {
                _ = scanner.scanCharacter()
            }
        }
        return (adults, children)
    }

    static func parseCarNumber(_ s: String) -> Int? {
        guard s.hasSuffix("号車") else { return nil }
        let body = String(s.dropLast("号車".count)).trimmingCharacters(in: .whitespaces)
        return Int(body)
    }

    static func parseSeats(_ s: String) -> [String]? {
        let scanner = Scanner(string: s)
        scanner.charactersToBeSkipped = .whitespaces
        guard let row = scanner.scanInt() else { return nil }
        guard scanner.scanString("番") != nil else { return nil }

        var letters: [String] = []
        let lettersSet = CharacterSet(charactersIn: "ABCDE")
        while !scanner.isAtEnd {
            if let ch = scanner.scanCharacters(from: lettersSet) {
                for c in ch {
                    letters.append(String(c))
                }
            } else if scanner.scanString("/") != nil {
                continue
            } else if scanner.scanString("席") != nil {
                break
            } else {
                _ = scanner.scanCharacter()
            }
        }

        guard !letters.isEmpty else { return nil }
        return letters.map { "\(row)\($0)" }
    }

    static func isTrainName(_ s: String) -> Bool {
        for kind in Reservation.TrainKind.allCases {
            if s.hasPrefix(kind.rawValue) { return true }
        }
        return false
    }

    static func parseTrainKindAndNumber(_ s: String) -> (Reservation.TrainKind?, Int?) {
        for kind in Reservation.TrainKind.allCases {
            if s.hasPrefix(kind.rawValue) {
                let rest = s.dropFirst(kind.rawValue.count).trimmingCharacters(in: .whitespaces)
                let digits = rest.prefix(while: { $0.isNumber })
                return (kind, Int(digits))
            }
        }
        return (nil, nil)
    }

    static func combine(date: Date, time: String?) -> Date? {
        guard let time else { return nil }
        let parts = time.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        var comps = jstCalendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = h
        comps.minute = m
        return jstCalendar.date(from: comps)
    }
}
