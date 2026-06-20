import Foundation
import UniformTypeIdentifiers

enum ChatAuthor: Equatable {
  case me
  case other(displayName: String)
}

enum ChatMessageKind: Equatable {
  case text(String)
  case media(Media)
  case file(FileAttachment)

  struct Media: Equatable {
    enum MediaType: Equatable {
      case image
      case video
    }

    var type: MediaType
    var localURL: URL
    var thumbnailURL: URL?
  }

  struct FileAttachment: Equatable {
    var localURL: URL
    var filename: String
    var contentType: UTType?
    var fileSizeBytes: Int64?
  }
}

struct ChatMessage: Equatable, Identifiable {
  var id: UUID
  var author: ChatAuthor
  var sentAt: Date
  var kind: ChatMessageKind
  var deliveryState: MessageDeliveryState
  var sendAttemptCount: Int

  init(
    id: UUID = UUID(),
    author: ChatAuthor,
    sentAt: Date = Date(),
    kind: ChatMessageKind,
    deliveryState: MessageDeliveryState = .sent,
    sendAttemptCount: Int = 0
  ) {
    self.id = id
    self.author = author
    self.sentAt = sentAt
    self.kind = kind
    self.deliveryState = deliveryState
    self.sendAttemptCount = sendAttemptCount
  }
}
