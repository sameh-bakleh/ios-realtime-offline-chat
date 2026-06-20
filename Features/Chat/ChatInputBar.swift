import UIKit

final class ChatInputBar: UIView, UITextViewDelegate {
  var onSendText: ((String) -> Void)?
  var onTapAttachment: (() -> Void)?

  private let topBorder = UIView()
  private let container = UIView()

  private let attachmentButton = UIButton(type: .system)
  private let sendButton = UIButton(type: .system)
  private let textView = UITextView()
  private let placeholderLabel = UILabel()

  private var heightConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .systemBackground
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.06
    layer.shadowRadius = 10
    layer.shadowOffset = CGSize(width: 0, height: -2)

    topBorder.translatesAutoresizingMaskIntoConstraints = false
    topBorder.backgroundColor = UIColor.separator.withAlphaComponent(0.6)
    addSubview(topBorder)

    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = UIColor.secondarySystemBackground
    container.layer.cornerRadius = 18
    container.layer.cornerCurve = .continuous
    addSubview(container)

    attachmentButton.translatesAutoresizingMaskIntoConstraints = false
    attachmentButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
    attachmentButton.tintColor = .secondaryLabel
    attachmentButton.addTarget(self, action: #selector(didTapAttachment), for: .touchUpInside)
    container.addSubview(attachmentButton)

    sendButton.translatesAutoresizingMaskIntoConstraints = false
    sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
    sendButton.tintColor = AppTheme.brandBlue
    sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
    container.addSubview(sendButton)

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.backgroundColor = .clear
    textView.font = .preferredFont(forTextStyle: .body)
    textView.textContainerInset = UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4)
    textView.textContainer.lineFragmentPadding = 0
    textView.delegate = self
    textView.isScrollEnabled = false
    container.addSubview(textView)

    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    placeholderLabel.text = "Write a message…"
    placeholderLabel.font = .preferredFont(forTextStyle: .body)
    placeholderLabel.textColor = .tertiaryLabel
    container.addSubview(placeholderLabel)

    heightConstraint = heightAnchor.constraint(equalToConstant: 60)
    heightConstraint?.priority = .defaultHigh
    heightConstraint?.isActive = true

    NSLayoutConstraint.activate([
      topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
      topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
      topBorder.topAnchor.constraint(equalTo: topAnchor),
      topBorder.heightAnchor.constraint(equalToConstant: 0.5),

      container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      container.topAnchor.constraint(equalTo: topAnchor, constant: 10),
      container.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),

      attachmentButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
      attachmentButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
      attachmentButton.widthAnchor.constraint(equalToConstant: 34),
      attachmentButton.heightAnchor.constraint(equalToConstant: 34),

      sendButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
      sendButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
      sendButton.widthAnchor.constraint(equalToConstant: 34),
      sendButton.heightAnchor.constraint(equalToConstant: 34),

      textView.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 6),
      textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6),
      textView.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
      textView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),

      placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 4),
      placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10),
      placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor)
    ])

    updateSendEnabled()
  }

  @objc private func didTapAttachment() {
    onTapAttachment?()
  }

  @objc private func didTapSend() {
    let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    onSendText?(text)
    textView.text = ""
    textViewDidChange(textView)
  }

  func textViewDidChange(_ textView: UITextView) {
    placeholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
    updateSendEnabled()
    invalidateIntrinsicContentSize()
    superview?.layoutIfNeeded()
  }

  private func updateSendEnabled() {
    let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    sendButton.isEnabled = !text.isEmpty
    sendButton.alpha = sendButton.isEnabled ? 1 : 0.4
  }

  override var intrinsicContentSize: CGSize {
    let targetWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
    let fittingSize = CGSize(width: targetWidth - 24 - 34 - 34 - 22, height: UIView.layoutFittingCompressedSize.height)
    let textHeight = textView.sizeThatFits(fittingSize).height

    let minTextHeight: CGFloat = 40
    let maxTextHeight: CGFloat = 120
    let clamped = min(max(textHeight, minTextHeight), maxTextHeight)

    return CGSize(width: UIView.noIntrinsicMetric, height: clamped + 20)
  }
}

