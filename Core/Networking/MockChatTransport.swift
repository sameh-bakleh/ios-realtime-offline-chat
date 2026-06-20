import Foundation

/// Local mock transport that simulates network latency, offline mode, and transient failures.
/// No API keys or external services required.
final class MockChatTransport: ChatTransport {
  var isSimulatedOffline = false
  var simulatedLatencySeconds: TimeInterval
  var simulatedFailureRate: Double

  init(
    latencySeconds: TimeInterval = MockChatConfiguration.simulatedLatencySeconds,
    failureRate: Double = MockChatConfiguration.simulatedFailureRate
  ) {
    simulatedLatencySeconds = latencySeconds
    simulatedFailureRate = failureRate
  }

  func send(_ message: OutboundChatMessage) async throws {
    if isSimulatedOffline {
      throw ChatTransportError.offline
    }

    let latency = max(0, simulatedLatencySeconds)
    if latency > 0 {
      try await Task.sleep(nanoseconds: UInt64(latency * 1_000_000_000))
    }

    if shouldFail() {
      throw ChatTransportError.simulatedFailure
    }
  }

  private func shouldFail() -> Bool {
    guard simulatedFailureRate > 0 else { return false }
    return Double.random(in: 0...1) < simulatedFailureRate
  }
}
