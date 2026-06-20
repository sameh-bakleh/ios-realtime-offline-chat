import AVFoundation
import UIKit

final class ChatMessageCell: UITableViewCell {
  static let reuseID = "ChatMessageCell"

  private let bubble = UIView()
  private let timeLabel = UILabel()
  private let deliveryStatusView = DeliveryStatusView()

  private let textLabelView = UILabel()

  private let mediaImageView = UIImageView()
  private let videoBadgeView = UIImageView(image: UIImage(systemName: "play.circle.fill"))
  private let videoMetaPill = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
  private let videoMetaLabel = UILabel()
  private var mediaHeightConstraint: NSLayoutConstraint?

  private let fileRow = UIStackView()
  private let fileIcon = UIImageView(image: UIImage(systemName: "doc.fill"))
  private let fileNameLabel = UILabel()
  private let fileMetaLabel = UILabel()

  private var bubbleLeadingMin: NSLayoutConstraint?
  private var bubbleTrailingMax: NSLayoutConstraint?
  private var bubbleLeadingAlign: NSLayoutConstraint?
  private var bubbleTrailingAlign: NSLayoutConstraint?

  var onRetryTapped: ((UUID) -> Void)?
  private var messageID: UUID?
  private var currentMediaURL: URL?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    currentMediaURL = nil
    textLabelView.text = nil
    mediaImageView.image = nil
    fileNameLabel.text = nil
    fileMetaLabel.text = nil
    videoBadgeView.isHidden = true
    videoMetaPill.isHidden = true
    videoMetaLabel.text = nil
    deliveryStatusView.reset()
    messageID = nil
    onRetryTapped = nil
  }

  private func setup() {
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    bubble.translatesAutoresizingMaskIntoConstraints = false
    bubble.layer.cornerRadius = 18
    bubble.layer.cornerCurve = .continuous
    contentView.addSubview(bubble)

    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.font = .preferredFont(forTextStyle: .caption2)
    timeLabel.textColor = .secondaryLabel
    bubble.addSubview(timeLabel)

    deliveryStatusView.translatesAutoresizingMaskIntoConstraints = false
    bubble.addSubview(deliveryStatusView)

    textLabelView.translatesAutoresizingMaskIntoConstraints = false
    textLabelView.font = .preferredFont(forTextStyle: .body)
    textLabelView.numberOfLines = 0
    bubble.addSubview(textLabelView)

    mediaImageView.translatesAutoresizingMaskIntoConstraints = false
    mediaImageView.contentMode = .scaleAspectFill
    mediaImageView.layer.cornerRadius = 18
    mediaImageView.layer.cornerCurve = .continuous
    mediaImageView.clipsToBounds = true
    mediaImageView.backgroundColor = UIColor.secondarySystemBackground
    bubble.addSubview(mediaImageView)

    videoBadgeView.translatesAutoresizingMaskIntoConstraints = false
    videoBadgeView.tintColor = .white
    videoBadgeView.isHidden = true
    bubble.addSubview(videoBadgeView)

    videoMetaPill.translatesAutoresizingMaskIntoConstraints = false
    videoMetaPill.clipsToBounds = true
    videoMetaPill.layer.cornerRadius = 10
    videoMetaPill.layer.cornerCurve = .continuous
    videoMetaPill.isHidden = true
    bubble.addSubview(videoMetaPill)

    videoMetaLabel.translatesAutoresizingMaskIntoConstraints = false
    videoMetaLabel.font = .preferredFont(forTextStyle: .caption2)
    videoMetaLabel.textColor = .white
    videoMetaLabel.textAlignment = .center
    videoMetaPill.contentView.addSubview(videoMetaLabel)

    fileRow.translatesAutoresizingMaskIntoConstraints = false
    fileRow.axis = .horizontal
    fileRow.spacing = 10
    fileRow.alignment = .center
    bubble.addSubview(fileRow)

    fileIcon.translatesAutoresizingMaskIntoConstraints = false
    fileIcon.tintColor = .label
    fileIcon.setContentHuggingPriority(.required, for: .horizontal)
    fileRow.addArrangedSubview(fileIcon)

    let fileTextColumn = UIStackView()
    fileTextColumn.axis = .vertical
    fileTextColumn.spacing = 2

    fileNameLabel.font = .preferredFont(forTextStyle: .subheadline)
    fileNameLabel.textColor = .label
    fileNameLabel.numberOfLines = 2

    fileMetaLabel.font = .preferredFont(forTextStyle: .caption2)
    fileMetaLabel.textColor = .secondaryLabel
    fileMetaLabel.numberOfLines = 1

    fileTextColumn.addArrangedSubview(fileNameLabel)
    fileTextColumn.addArrangedSubview(fileMetaLabel)
    fileRow.addArrangedSubview(fileTextColumn)

    let maxWidth = contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 0)
    maxWidth.isActive = false

    bubbleLeadingMin = bubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 14)
    bubbleTrailingMax = bubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -14)
    bubbleLeadingAlign = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14)
    bubbleTrailingAlign = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14)
    mediaHeightConstraint = mediaImageView.heightAnchor.constraint(equalToConstant: 190)

    NSLayoutConstraint.activate([
      bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
      bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),
      bubbleLeadingMin!,
      bubbleTrailingMax!,

      timeLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
      timeLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),

      deliveryStatusView.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
      deliveryStatusView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
      deliveryStatusView.leadingAnchor.constraint(greaterThanOrEqualTo: timeLabel.trailingAnchor, constant: 6),

      textLabelView.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
      textLabelView.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
      textLabelView.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
      textLabelView.bottomAnchor.constraint(lessThanOrEqualTo: timeLabel.topAnchor, constant: -6),

      mediaImageView.leadingAnchor.constraint(equalTo: bubble.leadingAnchor),
      mediaImageView.trailingAnchor.constraint(equalTo: bubble.trailingAnchor),
      mediaImageView.topAnchor.constraint(equalTo: bubble.topAnchor),
      mediaHeightConstraint!,
      // Critical: ensures the cell height includes the media (prevents overlap with next row)
      mediaImageView.bottomAnchor.constraint(lessThanOrEqualTo: timeLabel.topAnchor, constant: -8),

      videoBadgeView.centerXAnchor.constraint(equalTo: mediaImageView.centerXAnchor),
      videoBadgeView.centerYAnchor.constraint(equalTo: mediaImageView.centerYAnchor),
      videoBadgeView.widthAnchor.constraint(equalToConstant: 44),
      videoBadgeView.heightAnchor.constraint(equalToConstant: 44),

      videoMetaPill.trailingAnchor.constraint(equalTo: mediaImageView.trailingAnchor, constant: -10),
      videoMetaPill.bottomAnchor.constraint(equalTo: mediaImageView.bottomAnchor, constant: -10),

      videoMetaLabel.leadingAnchor.constraint(equalTo: videoMetaPill.contentView.leadingAnchor, constant: 10),
      videoMetaLabel.trailingAnchor.constraint(equalTo: videoMetaPill.contentView.trailingAnchor, constant: -10),
      videoMetaLabel.topAnchor.constraint(equalTo: videoMetaPill.contentView.topAnchor, constant: 6),
      videoMetaLabel.bottomAnchor.constraint(equalTo: videoMetaPill.contentView.bottomAnchor, constant: -6),

      fileRow.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
      fileRow.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
      fileRow.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 12),
      fileRow.bottomAnchor.constraint(lessThanOrEqualTo: timeLabel.topAnchor, constant: -8),

      fileIcon.widthAnchor.constraint(equalToConstant: 28),
      fileIcon.heightAnchor.constraint(equalToConstant: 28)
    ])

    bubbleLeadingAlign?.isActive = true
  }

  func configure(with message: ChatMessage) {
    messageID = message.id
    let isMe: Bool
    switch message.author {
    case .me: isMe = true
    case .other: isMe = false
    }

    bubbleLeadingAlign?.isActive = !isMe
    bubbleTrailingAlign?.isActive = isMe

    bubble.backgroundColor = isMe ? AppTheme.brandBlue : UIColor.secondarySystemBackground
    textLabelView.textColor = isMe ? .white : .label
    fileIcon.tintColor = isMe ? .white : .label
    fileNameLabel.textColor = isMe ? .white : .label
    fileMetaLabel.textColor = isMe ? UIColor.white.withAlphaComponent(0.85) : .secondaryLabel
    timeLabel.textColor = isMe ? UIColor.white.withAlphaComponent(0.7) : .secondaryLabel

    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    timeLabel.text = formatter.string(from: message.sentAt)

    if isMe {
      deliveryStatusView.isHidden = false
      deliveryStatusView.configure(state: message.deliveryState) { [weak self] in
        guard let id = self?.messageID else { return }
        self?.onRetryTapped?(id)
      }
    } else {
      deliveryStatusView.isHidden = true
    }

    switch message.kind {
    case .text(let text):
      textLabelView.isHidden = false
      mediaImageView.isHidden = true
      mediaHeightConstraint?.constant = 0
      fileRow.isHidden = true
      videoBadgeView.isHidden = true
      videoMetaPill.isHidden = true
      textLabelView.text = text

    case .media(let media):
      textLabelView.isHidden = true
      mediaImageView.isHidden = false
      fileRow.isHidden = true

      // Media should be edge-to-edge; avoid showing bubble background padding.
      bubble.backgroundColor = .clear

      currentMediaURL = media.localURL
      videoBadgeView.isHidden = (media.type != .video)
      videoMetaPill.isHidden = (media.type != .video)

      if media.type == .image {
        configureMediaHeightForImage(url: media.localURL)
        let pointSize = CGSize(width: 520, height: 520)
        mediaImageView.image = ImageDownsampler.downsample(url: media.localURL, to: pointSize)
      } else {
        mediaImageView.image = nil
        mediaHeightConstraint?.constant = 210
        generateVideoThumbnail(url: media.localURL)
        loadVideoDuration(url: media.localURL)
      }

    case .file(let file):
      textLabelView.isHidden = true
      mediaImageView.isHidden = true
      mediaHeightConstraint?.constant = 0
      fileRow.isHidden = false
      videoBadgeView.isHidden = true
      videoMetaPill.isHidden = true

      fileNameLabel.text = file.filename
      fileMetaLabel.text = [
        file.contentType?.preferredMIMEType ?? file.contentType?.identifier,
        file.fileSizeBytes.map(Self.formatBytes)
      ]
      .compactMap { $0 }
      .joined(separator: " • ")
    }
  }

  private func generateVideoThumbnail(url: URL) {
    let asset = AVAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true

    let time = CMTime(seconds: 0.1, preferredTimescale: 600)
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      let cgImage: CGImage?
      do {
        cgImage = try generator.copyCGImage(at: time, actualTime: nil)
      } catch {
        return
      }

      guard let cgImage else { return }
      let image = UIImage(cgImage: cgImage)
      DispatchQueue.main.async {
        guard self.currentMediaURL == url else { return }
        self.mediaImageView.image = image
      }
    }
  }

  private func loadVideoDuration(url: URL) {
    let asset = AVAsset(url: url)
    Task { @MainActor in
      let durationSeconds = CMTimeGetSeconds(asset.duration)
      guard durationSeconds.isFinite, durationSeconds > 0 else { return }
      videoMetaLabel.text = Self.formatDuration(durationSeconds)
    }
  }

  private func configureMediaHeightForImage(url: URL) {
    guard let pixelSize = ImageDownsampler.imagePixelSize(url: url) else {
      mediaHeightConstraint?.constant = 200
      return
    }
    let ratio = pixelSize.height / max(pixelSize.width, 1) // aspect (h/w)

    // Keep media previews compact in chat bubbles.
    let minH: CGFloat = 120
    let maxH: CGFloat = 240

    // Our bubble max width is ~78% of the screen; use a conservative base width.
    let baseWidth: CGFloat = 220

    // If the image is extremely tall, compress its preview height more aggressively.
    let adjustedRatio = min(ratio, 1.25)

    mediaHeightConstraint?.constant = min(max(baseWidth * adjustedRatio, minH), maxH)
  }

  private static func formatDuration(_ seconds: Double) -> String {
    let total = Int(seconds.rounded())
    let m = total / 60
    let s = total % 60
    return String(format: "%d:%02d", m, s)
  }

  private static func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

// MARK: - Delivery status chip

private final class DeliveryStatusView: UIView {
  private let iconView = UIImageView()
  private let spinner = UIActivityIndicatorView(style: .medium)
  private var onTap: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    iconView.translatesAutoresizingMaskIntoConstraints = false
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.hidesWhenStopped = true
    addSubview(iconView)
    addSubview(spinner)

    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
      iconView.trailingAnchor.constraint(equalTo: trailingAnchor),
      iconView.topAnchor.constraint(equalTo: topAnchor),
      iconView.bottomAnchor.constraint(equalTo: bottomAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 16),
      iconView.heightAnchor.constraint(equalToConstant: 16),
      spinner.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
      spinner.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
    addGestureRecognizer(tap)
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func reset() {
    spinner.stopAnimating()
    iconView.image = nil
    onTap = nil
    isUserInteractionEnabled = false
  }

  func configure(state: MessageDeliveryState, onRetry: @escaping () -> Void) {
    onTap = onRetry
    spinner.stopAnimating()
    iconView.isHidden = false

    switch state {
    case .sending, .retrying:
      iconView.isHidden = true
      spinner.startAnimating()
      isUserInteractionEnabled = false
    case .sent:
      iconView.image = UIImage(systemName: "checkmark")
      iconView.tintColor = UIColor.white.withAlphaComponent(0.75)
      isUserInteractionEnabled = false
    case .failed:
      iconView.image = UIImage(systemName: "exclamationmark.circle.fill")
      iconView.tintColor = .systemRed
      isUserInteractionEnabled = true
    }
  }

  @objc private func didTap() {
    onTap?()
  }
}

