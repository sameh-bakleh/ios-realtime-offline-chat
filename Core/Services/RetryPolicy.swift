import Foundation

enum RetryPolicy {
  /// Exponential backoff capped at 30 seconds (attempt is 1-based).
  static func delaySeconds(forAttempt attempt: Int) -> TimeInterval {
    let base = pow(2.0, Double(max(0, attempt - 1)))
    return min(base, 30)
  }

  static let maxAutomaticAttempts = 5
}
