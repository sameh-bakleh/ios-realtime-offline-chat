import Combine
import Foundation

final class ChatViewModel {
  @Published private(set) var messages: [ChatMessage] = []
  @Published private(set) var connectivity: ConnectivityState = .online

  let conversationID: UUID
  let conversationTitle: String

  private let repository: ChatRepositoryProtocol
  private var cancellables = Set<AnyCancellable>()

  init(conversationID: UUID, conversationTitle: String, repository: ChatRepositoryProtocol) {
    self.conversationID = conversationID
    self.conversationTitle = conversationTitle
    self.repository = repository

    repository.connectivityPublisher
      .receive(on: DispatchQueue.main)
      .assign(to: &$connectivity)

    repository.messagesDidChange
      .filter { $0 == conversationID }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in self?.reload() }
      .store(in: &cancellables)

    reload()
  }

  func reload() {
    messages = repository.loadMessages(conversationID: conversationID)
  }

  func sendText(_ text: String) {
    repository.sendText(text, conversationID: conversationID, conversationTitle: conversationTitle)
  }

  func sendMedia(_ media: ChatMessageKind.Media) {
    repository.sendMedia(media, conversationID: conversationID, conversationTitle: conversationTitle)
  }

  func sendFile(_ file: ChatMessageKind.FileAttachment) {
    repository.sendFile(file, conversationID: conversationID, conversationTitle: conversationTitle)
  }

  func retry(messageID: UUID) {
    repository.retrySend(messageID: messageID, conversationID: conversationID, isManual: true)
  }

  func deleteMessage(messageID: UUID) {
    repository.deleteMessage(messageID: messageID, conversationID: conversationID)
  }
}
