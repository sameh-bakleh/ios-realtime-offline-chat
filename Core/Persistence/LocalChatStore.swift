import Foundation

/// Simple on-disk JSON store (Documents/chat_store.json).
final class LocalChatStore {
  private let queue = DispatchQueue(label: "LocalChatStore.queue", qos: .userInitiated)
  private let url: URL

  private var cached: ChatStoreState?

  init(fileURL: URL? = nil) {
    if let fileURL {
      url = fileURL
    } else {
      let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      url = docs.appendingPathComponent("chat_store.json")
    }
  }

  func loadState() -> ChatStoreState {
    queue.sync {
      if let cached { return cached }
      let loaded = (try? Data(contentsOf: url)).flatMap { try? JSONDecoder.chat.decode(ChatStoreState.self, from: $0) }
      let state = loaded ?? ChatStoreState.seed()
      cached = state
      return state
    }
  }

  func saveState(_ mutate: (inout ChatStoreState) -> Void) {
    queue.sync {
      var state = cached ?? loadState()
      mutate(&state)
      cached = state
      do {
        let data = try JSONEncoder.chat.encode(state)
        try data.write(to: url, options: [.atomic])
      } catch {
        print("LocalChatStore save error: \(error)")
      }
    }
  }
}

// MARK: - Codable State

struct ChatStoreState: Codable, Equatable {
  var conversations: [ConversationRecord]
  var messagesByConversationID: [UUID: [ChatMessageRecord]]

  static func seed() -> ChatStoreState {
    let sam = UUID()
    let design = UUID()
    let recruiter = UUID()

    return ChatStoreState(
      conversations: [
        ConversationRecord(id: sam, title: "Alex Morgan", unreadCount: 2, pinned: false),
        ConversationRecord(id: design, title: "Design Team", unreadCount: 0, pinned: false),
        ConversationRecord(id: recruiter, title: "Hiring Team", unreadCount: 1, pinned: false)
      ],
      messagesByConversationID: [
        sam: [
          ChatMessageRecord(author: .other(displayName: "Alex"), kind: .text("Hey — can you send the doc + a screenshot?"), sentAt: Date().addingTimeInterval(-300), deliveryState: .sent),
          ChatMessageRecord(author: .me, kind: .text("Sure."), sentAt: Date().addingTimeInterval(-240), deliveryState: .sent)
        ],
        design: [
          ChatMessageRecord(author: .other(displayName: "Amina"), kind: .text("Can we align on the attachment preview sizing?"), sentAt: Date().addingTimeInterval(-3600), deliveryState: .sent)
        ],
        recruiter: [
          ChatMessageRecord(author: .other(displayName: "HR"), kind: .text("Thanks — received your resume.pdf"), sentAt: Date().addingTimeInterval(-86400), deliveryState: .sent)
        ]
      ]
    )
  }
}

struct ConversationRecord: Codable, Equatable, Identifiable {
  var id: UUID
  var title: String
  var unreadCount: Int
  var pinned: Bool
}

struct ChatMessageRecord: Codable, Equatable, Identifiable {
  var id: UUID
  var author: ChatAuthorRecord
  var sentAt: Date
  var kind: ChatMessageKindRecord
  var deliveryState: MessageDeliveryState?
  var sendAttemptCount: Int

  init(
    id: UUID = UUID(),
    author: ChatAuthorRecord,
    kind: ChatMessageKindRecord,
    sentAt: Date = Date(),
    deliveryState: MessageDeliveryState? = nil,
    sendAttemptCount: Int = 0
  ) {
    self.id = id
    self.author = author
    self.sentAt = sentAt
    self.kind = kind
    self.deliveryState = deliveryState
    self.sendAttemptCount = sendAttemptCount
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    author = try container.decode(ChatAuthorRecord.self, forKey: .author)
    sentAt = try container.decode(Date.self, forKey: .sentAt)
    kind = try container.decode(ChatMessageKindRecord.self, forKey: .kind)
    deliveryState = try container.decodeIfPresent(MessageDeliveryState.self, forKey: .deliveryState)
    sendAttemptCount = try container.decodeIfPresent(Int.self, forKey: .sendAttemptCount) ?? 0
  }
}

enum ChatAuthorRecord: Codable, Equatable {
  case me
  case other(displayName: String)
}

enum ChatMessageKindRecord: Codable, Equatable {
  case text(String)
  case media(MediaRecord)
  case file(FileRecord)

  struct MediaRecord: Codable, Equatable {
    enum MediaType: String, Codable, Equatable { case image, video }
    var type: MediaType
    var relativePath: String
  }

  struct FileRecord: Codable, Equatable {
    var filename: String
    var relativePath: String
    var utiIdentifier: String?
    var fileSizeBytes: Int64?
  }
}

private extension JSONDecoder {
  static var chat: JSONDecoder {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return d
  }
}

private extension JSONEncoder {
  static var chat: JSONEncoder {
    let e = JSONEncoder()
    e.outputFormatting = [.prettyPrinted, .sortedKeys]
    e.dateEncodingStrategy = .iso8601
    return e
  }
}

