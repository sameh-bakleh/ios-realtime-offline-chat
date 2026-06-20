import Foundation

/// Default mock transport settings for clone-and-run portfolio builds.
/// Override in tests or previews via `ChatTransport` properties.
enum MockChatConfiguration {
  static let simulatedLatencySeconds: TimeInterval = 0.45
  static let simulatedFailureRate: Double = 0.12
}
