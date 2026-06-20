import XCTest
@testable import RealtimeOfflineChat

final class ChatRepositoryTests: XCTestCase {
  private var storeURL: URL!
  private var store: LocalChatStore!
  private var transport: MockChatTransport!
  private var repository: ChatRepository!

  override func setUp() {
    super.setUp()
    storeURL = FileManager.default.temporaryDirectory.appendingPathComponent("chat-test-\(UUID().uuidString).json")
    store = LocalChatStore(fileURL: storeURL)
    transport = MockChatTransport(latencySeconds: 0.01, failureRate: 0)
    let connectivity = ConnectivityMonitor(transport: transport)
    repository = ChatRepository(store: store, transport: transport, connectivity: connectivity)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: storeURL)
    super.tearDown()
  }

  func testSendTextTransitionsToSent() async throws {
    let conversationID = UUID()
    seedConversation(conversationID)

    repository.sendText("Hello", conversationID: conversationID, conversationTitle: "Test")

    try await TestSupport.waitUntil(timeout: 2) {
      let messages = self.repository.loadMessages(conversationID: conversationID)
      return messages.count == 1 && messages[0].deliveryState == .sent
    }
  }

  func testOfflineSendMarksFailed() async throws {
    transport.isSimulatedOffline = true
    let conversationID = UUID()
    seedConversation(conversationID)

    repository.sendText("Queued", conversationID: conversationID, conversationTitle: "Test")

    try await TestSupport.waitUntil(timeout: 2) {
      self.repository.loadMessages(conversationID: conversationID).first?.deliveryState == .failed
    }
  }

  func testManualRetryAfterFailureEventuallySends() async throws {
    transport.isSimulatedOffline = true
    let conversationID = UUID()
    seedConversation(conversationID)

    repository.sendText("Retry me", conversationID: conversationID, conversationTitle: "Test")
    try await TestSupport.waitUntil(timeout: 2) {
      self.repository.loadMessages(conversationID: conversationID).first?.deliveryState == .failed
    }

    transport.isSimulatedOffline = false
    let messageID = repository.loadMessages(conversationID: conversationID)[0].id
    repository.retrySend(messageID: messageID, conversationID: conversationID, isManual: true)

    try await TestSupport.waitUntil(timeout: 2) {
      self.repository.loadMessages(conversationID: conversationID)[0].deliveryState == .sent
    }
  }

  func testRetryingStateDuringManualRetry() async throws {
    transport.isSimulatedOffline = true
    let conversationID = UUID()
    seedConversation(conversationID)

    repository.sendText("Retry path", conversationID: conversationID, conversationTitle: "Test")
    try await TestSupport.waitUntil(timeout: 2) {
      self.repository.loadMessages(conversationID: conversationID).first?.deliveryState == .failed
    }

    transport.isSimulatedOffline = false
    transport.simulatedLatencySeconds = 0.5
    let messageID = repository.loadMessages(conversationID: conversationID)[0].id
    repository.retrySend(messageID: messageID, conversationID: conversationID, isManual: true)

    try await TestSupport.waitUntil(timeout: 1) {
      self.repository.loadMessages(conversationID: conversationID)[0].deliveryState == .retrying
    }

    try await TestSupport.waitUntil(timeout: 2) {
      self.repository.loadMessages(conversationID: conversationID)[0].deliveryState == .sent
    }
  }

  func testFlushFailedMessagesOnReconnect() async throws {
    repository.setSimulatedOffline(true)
    let conversationID = UUID()
    seedConversation(conversationID)

    repository.sendText("Auto retry", conversationID: conversationID, conversationTitle: "Test")
    try await TestSupport.waitUntil(timeout: 2) {
      self.repository.loadMessages(conversationID: conversationID).first?.deliveryState == .failed
    }

    repository.setSimulatedOffline(false)

    try await TestSupport.waitUntil(timeout: 3) {
      self.repository.loadMessages(conversationID: conversationID)[0].deliveryState == .sent
    }
  }

  func testDeleteMessagePersists() {
    let conversationID = UUID()
    let messageID = UUID()
    store.saveState { state in
      state.conversations = [ConversationRecord(id: conversationID, title: "Test", unreadCount: 0, pinned: false)]
      state.messagesByConversationID[conversationID] = [
        ChatMessageRecord(id: messageID, author: .me, kind: .text("x"), deliveryState: .sent)
      ]
    }

    repository.deleteMessage(messageID: messageID, conversationID: conversationID)
    XCTAssertTrue(repository.loadMessages(conversationID: conversationID).isEmpty)
  }

  private func seedConversation(_ conversationID: UUID) {
    store.saveState { state in
      state.conversations = [ConversationRecord(id: conversationID, title: "Test", unreadCount: 0, pinned: false)]
      state.messagesByConversationID[conversationID] = []
    }
  }
}
