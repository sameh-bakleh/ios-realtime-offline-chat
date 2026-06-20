import Combine
import Foundation

final class InboxViewModel {
  @Published private(set) var conversations: [Conversation] = []
  @Published private(set) var connectivity: ConnectivityState = .online
  @Published private(set) var selectedFilter: InboxFilter = .all

  private let repository: ChatRepositoryProtocol
  private var cancellables = Set<AnyCancellable>()
  private var searchText = ""

  enum InboxFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case pinned = "Pinned"
  }

  init(repository: ChatRepositoryProtocol) {
    self.repository = repository
    repository.connectivityPublisher
      .receive(on: DispatchQueue.main)
      .assign(to: &$connectivity)

    repository.messagesDidChange
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in self?.reload() }
      .store(in: &cancellables)

    reload()
  }

  func reload() {
    conversations = repository.loadConversations()
  }

  func setFilter(_ filter: InboxFilter) {
    selectedFilter = filter
  }

  func setSearchText(_ text: String) {
    searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func displayedConversations(isSearching: Bool) -> [Conversation] {
    let base = isSearching ? filteredBySearch() : conversations
    return filteredByChip(base).sorted(by: sortRule)
  }

  func pinnedSection(isSearching: Bool) -> [Conversation] {
    displayedConversations(isSearching: isSearching).filter(\.pinned)
  }

  func recentSection(isSearching: Bool) -> [Conversation] {
    displayedConversations(isSearching: isSearching).filter { !$0.pinned }
  }

  func markRead(conversationID: UUID) {
    repository.markRead(conversationID: conversationID)
    reload()
  }

  func togglePinned(conversationID: UUID) {
    repository.togglePinned(conversationID: conversationID)
    reload()
  }

  func deleteConversation(conversationID: UUID) {
    repository.deleteConversation(conversationID: conversationID)
    reload()
  }

  func createConversation(title: String) -> Conversation {
    let conversation = repository.createConversation(title: title)
    reload()
    return conversation
  }

  func setSimulatedOffline(_ offline: Bool) {
    repository.setSimulatedOffline(offline)
  }

  private func filteredBySearch() -> [Conversation] {
    guard !searchText.isEmpty else { return conversations }
    return conversations.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.lastMessagePreview.localizedCaseInsensitiveContains(searchText)
    }
  }

  private func filteredByChip(_ list: [Conversation]) -> [Conversation] {
    switch selectedFilter {
    case .all: return list
    case .unread: return list.filter { $0.unreadCount > 0 }
    case .pinned: return list.filter(\.pinned)
    }
  }

  private func sortRule(_ lhs: Conversation, _ rhs: Conversation) -> Bool {
    if lhs.pinned != rhs.pinned { return lhs.pinned && !rhs.pinned }
    return lhs.lastActivityAt > rhs.lastActivityAt
  }
}
