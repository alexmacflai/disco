import Foundation

final class CopyEngine {

    // MARK: - JSON models (match NotificationCopy.json)

    private struct Root: Decodable {
        let schemaVersion: Int?
        let stages: [Stage]
    }

    private struct Stage: Decodable {
        let id: String?
        let startAfterSeconds: Int
        let intervalSeconds: Interval
        let messages: [Message]
    }

    private struct Interval: Decodable {
        let min: Int
        let max: Int
    }

    private struct Message: Decodable {
        let id: String
        let title: String
        let body: String

        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case body
        }
    }

    // MARK: - State

    private let root: Root
    private let stagesSorted: [Stage]

    // MARK: - Init

    init() {
        guard
            let url = Bundle.main.url(forResource: "NotificationCopy", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            fatalError("Failed to load NotificationCopy.json from bundle")
        }

        do {
            self.root = try JSONDecoder().decode(Root.self, from: data)
        } catch {
            fatalError("Failed to decode NotificationCopy.json: \(error)")
        }

        self.stagesSorted = root.stages.sorted { $0.startAfterSeconds < $1.startAfterSeconds }
    }

    // MARK: - Public API

    /// Picks a message appropriate for the given elapsed time.
    /// This is the API used by `NotificationScheduler`.
    func makeMessage(elapsedSeconds: Int) -> (title: String, body: String, copyId: String) {
        let stage = stageForElapsed(elapsedSeconds)
        guard let message = stage.messages.randomElement() ?? stage.messages.first else {
            return ("…", "…", "missing_message")
        }

        let title = replacePlaceholders(message.title, elapsedSeconds: elapsedSeconds, replacements: [:])
        let body = replacePlaceholders(message.body, elapsedSeconds: elapsedSeconds, replacements: [:])
        return (title, body, message.id)
    }

    /// Same as `makeMessage(elapsedSeconds:)`, but allows extra custom placeholders.
    func makeMessage(elapsedSeconds: Int, replacements: [String: String]) -> (title: String, body: String, copyId: String) {
        let stage = stageForElapsed(elapsedSeconds)
        guard let message = stage.messages.randomElement() ?? stage.messages.first else {
            return ("…", "…", "missing_message")
        }

        let title = replacePlaceholders(message.title, elapsedSeconds: elapsedSeconds, replacements: replacements)
        let body = replacePlaceholders(message.body, elapsedSeconds: elapsedSeconds, replacements: replacements)
        return (title, body, message.id)
    }

    /// Returns the random delay (in seconds) before the next notification.
    func nextInterval(elapsedSeconds: Int) -> Int {
        let stage = stageForElapsed(elapsedSeconds)
        let minVal = min(stage.intervalSeconds.min, stage.intervalSeconds.max)
        let maxVal = max(stage.intervalSeconds.min, stage.intervalSeconds.max)
        return Int.random(in: minVal...maxVal)
    }

    // MARK: - Internals

    private func stageForElapsed(_ elapsed: Int) -> Stage {
        stagesSorted.last { elapsed >= $0.startAfterSeconds } ?? stagesSorted.first!
    }

    private func replacePlaceholders(_ text: String, elapsedSeconds: Int, replacements: [String: String]) -> String {
        var result = text

        let minutes = elapsedSeconds / 60
        let hours = elapsedSeconds / 3600

        result = result.replacingOccurrences(of: "{elapsedSeconds}", with: String(elapsedSeconds))
        result = result.replacingOccurrences(of: "{elapsedMinutes}", with: String(minutes))
        result = result.replacingOccurrences(of: "{elapsedHours}", with: String(hours))

        for (key, value) in replacements {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return result
    }
}
