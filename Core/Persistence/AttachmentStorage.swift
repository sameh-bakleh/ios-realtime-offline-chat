import Foundation
import UniformTypeIdentifiers

enum AttachmentStorage {
  static func attachmentsDir() -> URL {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dir = docs.appendingPathComponent("Attachments", isDirectory: true)
    if !FileManager.default.fileExists(atPath: dir.path) {
      try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir
  }

  /// Copies a file into Documents/Attachments/ and returns the destination URL.
  static func persistPickedFile(from src: URL, preferredExtension: String? = nil) throws -> URL {
    let ext = !src.pathExtension.isEmpty ? src.pathExtension : (preferredExtension ?? "dat")
    let filename = "att-\(UUID().uuidString).\(ext)"
    let dst = attachmentsDir().appendingPathComponent(filename)

    if FileManager.default.fileExists(atPath: dst.path) {
      try FileManager.default.removeItem(at: dst)
    }
    try FileManager.default.copyItem(at: src, to: dst)
    return dst
  }

  /// Converts an absolute attachments URL to a relative path suitable for persistence.
  static func relativePathIfInAttachments(_ url: URL) -> String? {
    let dir = attachmentsDir().standardizedFileURL.path
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(dir + "/") else { return nil }
    return String(path.dropFirst(dir.count + 1))
  }

  static func urlFromAttachmentsRelativePath(_ relative: String) -> URL {
    attachmentsDir().appendingPathComponent(relative)
  }
}

