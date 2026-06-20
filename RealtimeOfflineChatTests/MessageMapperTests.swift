import XCTest
@testable import RealtimeOfflineChat

final class MessageMapperTests: XCTestCase {
  func testOutboundMessageMapsDeliveryStateForMe() {
    let record = ChatMessageRecord(author: .me, kind: .text("Hi"), deliveryState: .failed, sendAttemptCount: 2)
    let ui = MessageMapper.toUI(record)
    XCTAssertEqual(ui.deliveryState, .failed)
    XCTAssertEqual(ui.sendAttemptCount, 2)
  }

  func testInboundMessageAlwaysShowsSent() {
    let record = ChatMessageRecord(author: .other(displayName: "Alex"), kind: .text("Hi"), deliveryState: .failed)
    let ui = MessageMapper.toUI(record)
    XCTAssertEqual(ui.deliveryState, .sent)
  }
}
