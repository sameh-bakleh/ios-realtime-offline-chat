import XCTest
@testable import RealtimeOfflineChat

final class MessageDeliveryStateTests: XCTestCase {
  func testSendingCanBecomeSentOrFailed() {
    XCTAssertTrue(MessageDeliveryState.sending.canTransition(to: .sent))
    XCTAssertTrue(MessageDeliveryState.sending.canTransition(to: .failed))
    XCTAssertFalse(MessageDeliveryState.sending.canTransition(to: .retrying))
    XCTAssertFalse(MessageDeliveryState.sending.canTransition(to: .sending))
  }

  func testFailedCanRetryAndComplete() {
    XCTAssertTrue(MessageDeliveryState.failed.canTransition(to: .retrying))
    XCTAssertFalse(MessageDeliveryState.failed.canTransition(to: .sent))
    XCTAssertFalse(MessageDeliveryState.failed.canTransition(to: .sending))
    XCTAssertTrue(MessageDeliveryState.retrying.canTransition(to: .sent))
    XCTAssertTrue(MessageDeliveryState.retrying.canTransition(to: .failed))
    XCTAssertFalse(MessageDeliveryState.retrying.canTransition(to: .sending))
  }

  func testSentIsTerminalForTransitions() {
    XCTAssertFalse(MessageDeliveryState.sent.canTransition(to: .sending))
    XCTAssertFalse(MessageDeliveryState.sent.canTransition(to: .failed))
    XCTAssertFalse(MessageDeliveryState.sent.canTransition(to: .retrying))
    XCTAssertTrue(MessageDeliveryState.sent.canTransition(to: .sent))
  }

  func testIsPendingReflectsInFlightStates() {
    XCTAssertTrue(MessageDeliveryState.sending.isPending)
    XCTAssertTrue(MessageDeliveryState.retrying.isPending)
    XCTAssertFalse(MessageDeliveryState.sent.isPending)
    XCTAssertFalse(MessageDeliveryState.failed.isPending)
  }

  func testInvalidTransitionsRejected() {
    let invalidPairs: [(MessageDeliveryState, MessageDeliveryState)] = [
      (.sending, .retrying),
      (.sent, .failed),
      (.sent, .sending),
      (.failed, .sent),
      (.failed, .failed),
      (.retrying, .retrying),
      (.retrying, .sending)
    ]

    for (from, to) in invalidPairs {
      XCTAssertFalse(
        from.canTransition(to: to),
        "Expected \(from) → \(to) to be invalid"
      )
    }
  }
}
