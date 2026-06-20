import Foundation

struct Conversation: Identifiable, Equatable {
  var id: UUID
  var title: String
  var lastMessagePreview: String
  var lastActivityAt: Date
  var unreadCount: Int
  var pinned: Bool

  init(
    id: UUID = UUID(),
    title: String,
    lastMessagePreview: String,
    lastActivityAt: Date = Date(),
    unreadCount: Int = 0,
    pinned: Bool = false
  ) {
    self.id = id
    self.title = title
    self.lastMessagePreview = lastMessagePreview
    self.lastActivityAt = lastActivityAt
    self.unreadCount = unreadCount
    self.pinned = pinned
  }
}
