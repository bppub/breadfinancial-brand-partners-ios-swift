import Foundation

final class LogCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    var recordedMessages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    func record(_ message: String) {
        lock.lock()
        messages.append(message)
        lock.unlock()
    }
}
