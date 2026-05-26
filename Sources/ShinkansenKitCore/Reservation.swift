import Foundation

public struct Reservation: Sendable, Equatable {
    public enum TrainKind: String, Sendable, Equatable, CaseIterable {
        case nozomi = "のぞみ"
        case hikari = "ひかり"
        case kodama = "こだま"
        case mizuho = "みずほ"
        case sakura = "さくら"
        case tsubame = "つばめ"
    }

    public enum SeatClass: Sendable, Equatable {
        case nonReserved
        case reservedOrdinary
        case greenCar
    }

    public struct Passengers: Sendable, Equatable {
        public let adults: Int
        public let children: Int

        public init(adults: Int, children: Int) {
            self.adults = adults
            self.children = children
        }
    }

    public let kind: TrainKind?
    public let trainNumber: Int?
    public let departureStation: String
    public let arrivalStation: String
    public let boardingDate: Date
    public let departureTime: Date?
    public let arrivalTime: Date?
    public let seatClass: SeatClass
    public let carNumber: Int?
    public let seats: [String]
    public let passengers: Passengers
    public let product: String
    public let formation: String
    public let smoking: Bool?

    public init(
        kind: TrainKind?,
        trainNumber: Int?,
        departureStation: String,
        arrivalStation: String,
        boardingDate: Date,
        departureTime: Date?,
        arrivalTime: Date?,
        seatClass: SeatClass,
        carNumber: Int?,
        seats: [String],
        passengers: Passengers,
        product: String,
        formation: String,
        smoking: Bool?
    ) {
        self.kind = kind
        self.trainNumber = trainNumber
        self.departureStation = departureStation
        self.arrivalStation = arrivalStation
        self.boardingDate = boardingDate
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.seatClass = seatClass
        self.carNumber = carNumber
        self.seats = seats
        self.passengers = passengers
        self.product = product
        self.formation = formation
        self.smoking = smoking
    }
}
