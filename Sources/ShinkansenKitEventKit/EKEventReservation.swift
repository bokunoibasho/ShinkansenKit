import Foundation
import ShinkansenKitCore

#if canImport(EventKit)
import EventKit

extension Reservation {
    public init?(from event: EKEvent, parser: ReservationParser = ReservationParser()) {
        guard let parsed = parser.parse(
            title: event.title,
            location: event.location,
            notes: event.notes
        ) else {
            return nil
        }
        self = parsed
    }
}
#endif
