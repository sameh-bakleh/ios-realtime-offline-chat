import Foundation

/// Abstraction for a real-time or REST chat backend (WebSocket, Firebase, HTTP).
/// The app ships with `MockChatTransport` — swap implementations without touching UI code.
protocol ChatTransport: AnyObject {
  var isSimulatedOffline: Bool { get set }
  var simulatedLatencySeconds: TimeInterval { get set }
  /// 0...1 probability of failure when online (for demo/testing).
  var simulatedFailureRate: Double { get set }

  func send(_ message: OutboundChatMessage) async throws
}

struct OutboundChatMessage: Equatable, Sendable {
  let id: UUID
  let conversationID: UUID
  let text: String?
  let attachmentRelativePath: String?
  let kind: OutboundKind

  enum OutboundKind: String, Equatable, Sendable {
    case text
    case media
    case file
  }
}

enum ChatTransportError: Error, Equatable {
  case offline
  case simulatedFailure
  case timeout
}
