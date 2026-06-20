import UIKit

final class ConversationCell: UITableViewCell {
  static let reuseID = "ConversationCell"

  private let avatarView = UIView()
  private let initialsLabel = UILabel()

  private let titleLabel = UILabel()
  private let previewLabel = UILabel()
  private let timeLabel = UILabel()
  private let pinnedIcon = UIImageView(image: UIImage(systemName: "pin.fill"))

  private let unreadBadge = UIView()
  private let unreadLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    selectionStyle = .default
    accessoryType = .disclosureIndicator

    avatarView.translatesAutoresizingMaskIntoConstraints = false
    avatarView.backgroundColor = AppTheme.brandBlue.withAlphaComponent(0.14)
    avatarView.layer.cornerRadius = 22
    avatarView.layer.cornerCurve = .continuous
    contentView.addSubview(avatarView)

    initialsLabel.translatesAutoresizingMaskIntoConstraints = false
    initialsLabel.font = .preferredFont(forTextStyle: .headline)
    initialsLabel.textColor = AppTheme.brandBlue
    initialsLabel.textAlignment = .center
    avatarView.addSubview(initialsLabel)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    contentView.addSubview(titleLabel)

    previewLabel.translatesAutoresizingMaskIntoConstraints = false
    previewLabel.font = .preferredFont(forTextStyle: .subheadline)
    previewLabel.textColor = .secondaryLabel
    previewLabel.numberOfLines = 2
    contentView.addSubview(previewLabel)

    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.font = .preferredFont(forTextStyle: .caption1)
    timeLabel.textColor = .secondaryLabel
    timeLabel.setContentHuggingPriority(.required, for: .horizontal)
    contentView.addSubview(timeLabel)

    pinnedIcon.translatesAutoresizingMaskIntoConstraints = false
    pinnedIcon.tintColor = AppTheme.brandOrange
    pinnedIcon.isHidden = true
    pinnedIcon.setContentHuggingPriority(.required, for: .horizontal)
    contentView.addSubview(pinnedIcon)

    unreadBadge.translatesAutoresizingMaskIntoConstraints = false
    unreadBadge.backgroundColor = AppTheme.brandBlue
    unreadBadge.layer.cornerRadius = 10
    unreadBadge.layer.cornerCurve = .continuous
    unreadBadge.isHidden = true
    contentView.addSubview(unreadBadge)

    unreadLabel.translatesAutoresizingMaskIntoConstraints = false
    unreadLabel.font = .preferredFont(forTextStyle: .caption2)
    unreadLabel.textColor = .white
    unreadLabel.textAlignment = .center
    unreadBadge.addSubview(unreadLabel)

    NSLayoutConstraint.activate([
      avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      avatarView.widthAnchor.constraint(equalToConstant: 44),
      avatarView.heightAnchor.constraint(equalToConstant: 44),

      initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
      initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
      timeLabel.trailingAnchor.constraint(equalTo: pinnedIcon.leadingAnchor, constant: -8),

      pinnedIcon.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
      pinnedIcon.widthAnchor.constraint(equalToConstant: 14),
      pinnedIcon.heightAnchor.constraint(equalToConstant: 14),
      pinnedIcon.trailingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: -10),

      titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -10),

      previewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
      previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      previewLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

      unreadBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      unreadBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
      unreadBadge.heightAnchor.constraint(equalToConstant: 20),
      unreadBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),

      unreadLabel.leadingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: 6),
      unreadLabel.trailingAnchor.constraint(equalTo: unreadBadge.trailingAnchor, constant: -6),
      unreadLabel.topAnchor.constraint(equalTo: unreadBadge.topAnchor, constant: 2),
      unreadLabel.bottomAnchor.constraint(equalTo: unreadBadge.bottomAnchor, constant: -2)
    ])
  }

  func configure(with conversation: Conversation) {
    titleLabel.text = conversation.title
    previewLabel.text = conversation.lastMessagePreview

    let initials = conversation.title
      .split(separator: " ")
      .prefix(2)
      .compactMap { $0.first }
      .map { String($0).uppercased() }
      .joined()
    initialsLabel.text = initials.isEmpty ? "?" : initials

    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    timeLabel.text = formatter.localizedString(for: conversation.lastActivityAt, relativeTo: Date())
    pinnedIcon.isHidden = !conversation.pinned

    if conversation.unreadCount > 0 {
      unreadBadge.isHidden = false
      unreadLabel.text = conversation.unreadCount > 99 ? "99+" : "\(conversation.unreadCount)"
      titleLabel.font = .preferredFont(forTextStyle: .headline).withTraits(.traitBold)
    } else {
      unreadBadge.isHidden = true
      unreadLabel.text = nil
      titleLabel.font = .preferredFont(forTextStyle: .headline)
    }
  }
}

private extension UIFont {
  func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}

