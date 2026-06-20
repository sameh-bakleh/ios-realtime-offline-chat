import Foundation
import UniformTypeIdentifiers

enum MessageMapper {
  static func toUI(_ record: ChatMessageRecord) -> ChatMessage {
    let author: ChatAuthor
    switch record.author {
    case .me: author = .me
    case .other(let displayName): author = .other(displayName: displayName)
    }

    let kind: ChatMessageKind
    switch record.kind {
    case .text(let t):
      kind = .text(t)
    case .media(let m):
      let url = AttachmentStorage.urlFromAttachmentsRelativePath(m.relativePath)
      let type: ChatMessageKind.Media.MediaType = (m.type == .image) ? .image : .video
      kind = .media(.init(type: type, localURL: url, thumbnailURL: nil))
    case .file(let f):
      let url = AttachmentStorage.urlFromAttachmentsRelativePath(f.relativePath)
      kind = .file(.init(
        localURL: url,
        filename: f.filename,
        contentType: f.utiIdentifier.flatMap(UTType.init),
        fileSizeBytes: f.fileSizeBytes
      ))
    }

    let delivery: MessageDeliveryState
    switch record.author {
    case .other:
      delivery = .sent
    case .me:
      delivery = record.deliveryState ?? .sent
    }

    return ChatMessage(
      id: record.id,
      author: author,
      sentAt: record.sentAt,
      kind: kind,
      deliveryState: delivery,
      sendAttemptCount: record.sendAttemptCount
    )
  }

  static func toRecord(_ message: ChatMessage) -> ChatMessageRecord {
    let author: ChatAuthorRecord
    switch message.author {
    case .me: author = .me
    case .other(let displayName): author = .other(displayName: displayName)
    }

    let kind: ChatMessageKindRecord
    switch message.kind {
    case .text(let t):
      kind = .text(t)
    case .media(let m):
      let rel = AttachmentStorage.relativePathIfInAttachments(m.localURL) ?? m.localURL.lastPathComponent
      let type: ChatMessageKindRecord.MediaRecord.MediaType = (m.type == .image) ? .image : .video
      kind = .media(.init(type: type, relativePath: rel))
    case .file(let f):
      let rel = AttachmentStorage.relativePathIfInAttachments(f.localURL) ?? f.localURL.lastPathComponent
      kind = .file(.init(
        filename: f.filename,
        relativePath: rel,
        utiIdentifier: f.contentType?.identifier,
        fileSizeBytes: f.fileSizeBytes
      ))
    }

    return ChatMessageRecord(
      id: message.id,
      author: author,
      kind: kind,
      sentAt: message.sentAt,
      deliveryState: message.author == .me ? message.deliveryState : .sent,
      sendAttemptCount: message.sendAttemptCount
    )
  }

  static func previewText(for kind: ChatMessageKindRecord) -> String {
    switch kind {
    case .text(let t): return t
    case .media(let m): return m.type == .image ? "📷 Photo" : "🎬 Video"
    case .file(let f): return "📎 \(f.filename)"
    }
  }

  static func toConversation(_ record: ConversationRecord, messages: [ChatMessageRecord]) -> Conversation {
    let last = messages.sorted(by: { $0.sentAt > $1.sentAt }).first
    let preview = last.map { previewText(for: $0.kind) } ?? "Start the conversation…"
    let ts = last?.sentAt ?? Date.distantPast
    return Conversation(
      id: record.id,
      title: record.title,
      lastMessagePreview: preview,
      lastActivityAt: ts,
      unreadCount: record.unreadCount,
      pinned: record.pinned
    )
  }
}
