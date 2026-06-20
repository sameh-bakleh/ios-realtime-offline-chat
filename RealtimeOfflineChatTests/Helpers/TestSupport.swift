import XCTest

enum TestSupport {
  static func waitUntil(
    timeout: TimeInterval,
    file: StaticString = #filePath,
    line: UInt = #line,
    condition: @escaping () -> Bool
  ) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if condition() { return }
      try await Task.sleep(nanoseconds: 50_000_000)
    }
    XCTFail("Condition not met before timeout", file: file, line: line)
  }
}
