import Foundation
import PofuCore
import Testing
@testable import PofuPersistence

/// Rehearsal mode's events keep their simulated tag through the log on
/// disk, and the live lines stay exactly as before.
@Suite("Event log sources")
struct EventSourceLogTests {
    let start = Date(timeIntervalSince1970: 1_793_610_000)

    @Test func theSimulatedTagSurvivesTheLog() throws {
        let directory = try TemporaryDirectory()
        let log = EventLog(directory: directory.url)
        let live = LoggedEvent(at: start, event: .hopUnavailable(app: .instagram))
        let simulated = LoggedEvent(at: start.addingTimeInterval(1), event: .guardedUsageMeasured(minutes: 15), source: .simulated)
        try log.append(live)
        try log.append(simulated)

        let read = try log.readAll()
        #expect(read == [live, simulated])
        #expect(read.filtered(by: .live) == [live])
        #expect(read.filtered(by: .simulated) == [simulated])

        let lines = try String(contentsOf: log.fileURL, encoding: .utf8).split(separator: "\n")
        #expect(lines.count == 2)
        #expect(!lines[0].contains("source"))
        #expect(lines[1].contains("\"source\":\"simulated\""))
    }
}
