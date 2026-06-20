import Combine
import Foundation

protocol ChatRepositoryProtocol: AnyObject {
  var connectivityPublisher: AnyPublisher<ConnectivityState, Never> { get }
  var messagesDidChange: AnyPublisher<UUID, Never> { get }

  func loadConversations() -> [Conversation]
  func loadMessages(conversationID: UUID) -> [ChatMessage]
  func markRead(conversationID: UUID)
  func togglePinned(conversationID: UUID)
  func deleteConversation(conversationID: UUID)
  func createConversation(title: String) -> Conversation
  func deleteMessage(messageID: UUID, conversationID: UUID)

  func sendText(_ text: String, conversationID: UUID, conversationTitle: String)
  func sendMedia(_ media: ChatMessageKind.Media, conversationID: UUID, conversationTitle: String)
  func sendFile(_ file: ChatMessageKind.FileAttachment, conversationID: UUID, conversationTitle: String)
  func retrySend(messageID: UUID, conversationID: UUID, isManual: Bool)

  func setSimulatedOffline(_ offline: Bool)
  func flushFailedMessages()
}

/// Coordinates local cache, optimistic writes, mock transport, and retry.
final class ChatRepository: ChatRepositoryProtocol {
  var connectivityPublisher: AnyPublisher<ConnectivityState, Never> {
    connectivity.statePublisher
  }

  private let messagesChanged = PassthroughSubject<UUID, Never>()
  var messagesDidChange: AnyPublisher<UUID, Never> {
    messagesChanged.eraseToAnyPublisher()
  }

  private let store: LocalChatStore
  private let transport: ChatTransport
  private let connectivity: ConnectivityMonitor
  private var cancellables = Set<AnyCancellable>()
  private var inFlight = Set<UUID>()

  init(store: LocalChatStore, transport: ChatTransport, connectivity: ConnectivityMonitor) {
    self.store = store
    self.transport = transport
    self.connectivity = connectivity

    connectivity.statePublisher
      .removeDuplicates()
      .filter { $0.isOnline }
      .sink { [weak self] _ in
        self?.flushFailedMessages()
      }
      .store(in: &cancellables)
  }

  func loadConversations() -> [Conversation] {
    let state = store.loadState()
    return state.conversations.map { record in
      let msgs = state.messagesByConversationID[record.id] ?? []
      return MessageMapper.toConversation(record, messages: msgs)
    }
  }

  func loadMessages(conversationID: UUID) -> [ChatMessage] {
    let state = store.loadState()
    let records = (state.messagesByConversationID[conversationID] ?? []).sorted(by: { $0.sentAt < $1.sentAt })
    return records.map(MessageMapper.toUI)
  }

  func markRead(conversationID: UUID) {
    store.saveState { state in
      if let idx = state.conversations.firstIndex(where: { $0.id == conversationID }) {
        state.conversations[idx].unreadCount = 0
      }
    }
    messagesChanged.send(conversationID)
  }

  func togglePinned(conversationID: UUID) {
    store.saveState { state in
      if let idx = state.conversations.firstIndex(where: { $0.id == conversationID }) {
        state.conversations[idx].pinned.toggle()
      }
    }
    messagesChanged.send(conversationID)
  }

  func deleteConversation(conversationID: UUID) {
    store.saveState { state in
      state.conversations.removeAll(where: { $0.id == conversationID })
      state.messagesByConversationID[conversationID] = nil
    }
    messagesChanged.send(conversationID)
  }

  func createConversation(title: String) -> Conversation {
    let id = UUID()
    store.saveState { state in
      state.conversations.insert(ConversationRecord(id: id, title: title, unreadCount: 0, pinned: false), at: 0)
      state.messagesByConversationID[id] = []
    }
    messagesChanged.send(id)
    return Conversation(id: id, title: title, lastMessagePreview: "Start the conversation…", lastActivityAt: Date(), unreadCount: 0)
  }

  func deleteMessage(messageID: UUID, conversationID: UUID) {
    store.saveState { state in
      state.messagesByConversationID[conversationID]?.removeAll(where: { $0.id == messageID })
    }
    messagesChanged.send(conversationID)
  }

  func sendText(_ text: String, conversationID: UUID, conversationTitle: String) {
    let message = ChatMessage(author: .me, kind: .text(text), deliveryState: .sending)
    enqueueOutbound(message: message, conversationID: conversationID, conversationTitle: conversationTitle)
  }

  func sendMedia(_ media: ChatMessageKind.Media, conversationID: UUID, conversationTitle: String) {
    let message = ChatMessage(author: .me, kind: .media(media), deliveryState: .sending)
    enqueueOutbound(message: message, conversationID: conversationID, conversationTitle: conversationTitle)
  }

  func sendFile(_ file: ChatMessageKind.FileAttachment, conversationID: UUID, conversationTitle: String) {
    let message = ChatMessage(author: .me, kind: .file(file), deliveryState: .sending)
    enqueueOutbound(message: message, conversationID: conversationID, conversationTitle: conversationTitle)
  }

  func retrySend(messageID: UUID, conversationID: UUID, isManual: Bool = true) {
    guard !inFlight.contains(messageID) else { return }
    let state = store.loadState()
    guard var record = state.messagesByConversationID[conversationID]?.first(where: { $0.id == messageID }) else { return }
    guard record.author == .me, record.deliveryState == .failed else { return }

    record.deliveryState = .retrying
    record.sendAttemptCount += 1
    updateRecord(record, conversationID: conversationID)
    dispatchSend(record: record, conversationID: conversationID, isManualRetry: isManual)
  }

  func setSimulatedOffline(_ offline: Bool) {
    connectivity.setSimulatedOffline(offline)
  }

  func flushFailedMessages() {
    let state = store.loadState()
    for (conversationID, records) in state.messagesByConversationID {
      for record in records where record.author == .me && record.deliveryState == .failed {
        guard record.sendAttemptCount < RetryPolicy.maxAutomaticAttempts else { continue }
        retrySend(messageID: record.id, conversationID: conversationID, isManual: false)
      }
    }
  }

  // MARK: - Private

  private func enqueueOutbound(message: ChatMessage, conversationID: UUID, conversationTitle: String) {
    let record = MessageMapper.toRecord(message)
    persistNewOutbound(record: record, conversationID: conversationID, conversationTitle: conversationTitle)
    dispatchSend(record: record, conversationID: conversationID, isManualRetry: false)
  }

  private func persistNewOutbound(record: ChatMessageRecord, conversationID: UUID, conversationTitle: String) {
    store.saveState { state in
      if state.messagesByConversationID[conversationID] == nil {
        state.messagesByConversationID[conversationID] = []
      }
      state.messagesByConversationID[conversationID]?.append(record)

      if let idx = state.conversations.firstIndex(where: { $0.id == conversationID }) {
        state.conversations[idx].title = conversationTitle
      } else {
        state.conversations.insert(
          ConversationRecord(id: conversationID, title: conversationTitle, unreadCount: 0, pinned: false),
          at: 0
        )
      }
    }
    messagesChanged.send(conversationID)
  }

  private func updateRecord(_ record: ChatMessageRecord, conversationID: UUID) {
    store.saveState { state in
      guard var list = state.messagesByConversationID[conversationID],
            let idx = list.firstIndex(where: { $0.id == record.id }) else { return }
      list[idx] = record
      state.messagesByConversationID[conversationID] = list
    }
    messagesChanged.send(conversationID)
  }

  private func dispatchSend(record: ChatMessageRecord, conversationID: UUID, isManualRetry: Bool) {
    guard !inFlight.contains(record.id) else { return }
    inFlight.insert(record.id)

    let outbound = makeOutbound(from: record, conversationID: conversationID)
    let attempt = record.sendAttemptCount

    Task { [weak self] in
      guard let self else { return }
      defer { self.inFlight.remove(record.id) }

      if !isManualRetry && attempt > 0 {
        let delay = RetryPolicy.delaySeconds(forAttempt: attempt)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      }

      do {
        try await self.transport.send(outbound)
        self.transition(recordID: record.id, conversationID: conversationID, to: .sent)
      } catch {
        self.transition(recordID: record.id, conversationID: conversationID, to: .failed)
      }
    }
  }

  private func transition(recordID: UUID, conversationID: UUID, to state: MessageDeliveryState) {
    store.saveState { storeState in
      guard var list = storeState.messagesByConversationID[conversationID],
            let idx = list.firstIndex(where: { $0.id == recordID }) else { return }
      var record = list[idx]
      let current = record.deliveryState ?? .sending
      guard current.canTransition(to: state) else { return }
      record.deliveryState = state
      list[idx] = record
      storeState.messagesByConversationID[conversationID] = list
    }
    messagesChanged.send(conversationID)
  }

  private func makeOutbound(from record: ChatMessageRecord, conversationID: UUID) -> OutboundChatMessage {
    switch record.kind {
    case .text(let text):
      return OutboundChatMessage(id: record.id, conversationID: conversationID, text: text, attachmentRelativePath: nil, kind: .text)
    case .media(let m):
      return OutboundChatMessage(id: record.id, conversationID: conversationID, text: nil, attachmentRelativePath: m.relativePath, kind: .media)
    case .file(let f):
      return OutboundChatMessage(id: record.id, conversationID: conversationID, text: nil, attachmentRelativePath: f.relativePath, kind: .file)
    }
  }
}
