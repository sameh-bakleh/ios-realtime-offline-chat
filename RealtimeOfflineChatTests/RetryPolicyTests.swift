import XCTest
@testable import RealtimeOfflineChat

final class RetryPolicyTests: XCTestCase {
  func testBackoffIncreasesAndCaps() {
    XCTAssertEqual(RetryPolicy.delaySeconds(forAttempt: 1), 1)
    XCTAssertEqual(RetryPolicy.delaySeconds(forAttempt: 2), 2)
    XCTAssertEqual(RetryPolicy.delaySeconds(forAttempt: 3), 4)
    XCTAssertEqual(RetryPolicy.delaySeconds(forAttempt: 10), 30)
  }
}
