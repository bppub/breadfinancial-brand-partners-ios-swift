import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct TimestampUtilitiesTests {
    @Test
    func formatsDateAsUTCTimestampWithMilliseconds() throws {
        let date = try #require(
            Calendar(identifier: .gregorian).date(
                from: DateComponents(
                    timeZone: TimeZone(secondsFromGMT: 5 * 60 * 60),
                    year: 2026,
                    month: 9,
                    day: 2,
                    hour: 10,
                    minute: 15,
                    second: 30,
                    nanosecond: 456_000_000
                )
            )
        )

        #expect(formattedUTCTimestamp(for: date) == "2026-09-02T05:15:30.456Z")
    }
}
