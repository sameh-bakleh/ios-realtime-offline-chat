import Foundation

/// Outbound message lifecycle for optimistic UI and offline retry.
enum MessageDeliveryState: String, Codable, Equatable, CaseIterable {
  case sending
  case sent
  case failed
  case retrying

  var isPending: Bool {
    switch self {
    case .sending, .retrying: return true
    case .sent, .failed: return false
    }
  }

  /// Valid transitions enforced in tests and repository logic.
  func canTransition(to next: MessageDeliveryState) -> Bool {
    switch (self, next) {
    case (.sending, .sent), (.sending, .failed):
      return true
    case (.failed, .retrying), (.retrying, .sent), (.retrying, .failed):
      return true
    case (.sent, .sent):
      return true
    default:
      return false
    }
  }
}

enum ConnectivityState: Equatable {
  case online
  case offline

  var isOnline: Bool { self == .online }
}
