import AVFoundation
import AVKit
import Combine
import PhotosUI
import QuickLook
import UIKit
import UniformTypeIdentifiers

final class ChatViewController: UIViewController {
  private let viewModel: ChatViewModel
  private var cancellables = Set<AnyCancellable>()

  private let tableView = UITableView(frame: .zero, style: .plain)
  private let inputBar = ChatInputBar()
  private var inputBarBottomConstraint: NSLayoutConstraint?

  private lazy var quickLookController = QLPreviewController()
  private var quickLookURL: URL?

  init(viewModel: ChatViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
    title = viewModel.conversationTitle
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never

    quickLookController.dataSource = self
    configureNavTitle()
    configureInputBar()
    configureTable()
    configureKeyboardHandling()
    bindViewModel()
  }

  private func bindViewModel() {
    viewModel.$messages
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.tableView.reloadData()
        self?.scrollToBottom(animated: true)
      }
      .store(in: &cancellables)

    viewModel.$connectivity
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.navigationItem.prompt = state.isOnline ? nil : "Offline — tap failed messages to retry"
      }
      .store(in: &cancellables)
  }

  private func configureNavTitle() {
    let titleStack = UIStackView()
    titleStack.axis = .horizontal
    titleStack.spacing = 10
    titleStack.alignment = .center

    let avatar = UIView()
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.backgroundColor = AppTheme.brandBlue.withAlphaComponent(0.14)
    avatar.layer.cornerRadius = 16
    avatar.layer.cornerCurve = .continuous

    let initialsLabel = UILabel()
    initialsLabel.translatesAutoresizingMaskIntoConstraints = false
    initialsLabel.font = .preferredFont(forTextStyle: .subheadline)
    initialsLabel.textColor = AppTheme.brandBlue
    initialsLabel.textAlignment = .center
    initialsLabel.text = viewModel.conversationTitle
      .split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
    avatar.addSubview(initialsLabel)

    NSLayoutConstraint.activate([
      avatar.widthAnchor.constraint(equalToConstant: 32),
      avatar.heightAnchor.constraint(equalToConstant: 32),
      initialsLabel.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
      initialsLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor)
    ])

    let labels = UIStackView()
    labels.axis = .vertical
    labels.spacing = 1

    let name = UILabel()
    name.font = .preferredFont(forTextStyle: .headline)
    name.text = viewModel.conversationTitle
    name.textColor = .label

    let status = UILabel()
    status.font = .preferredFont(forTextStyle: .caption1)
    status.textColor = .secondaryLabel
    status.text = "Active"

    labels.addArrangedSubview(name)
    labels.addArrangedSubview(status)
    titleStack.addArrangedSubview(avatar)
    titleStack.addArrangedSubview(labels)
    navigationItem.titleView = titleStack
  }

  private func configureTable() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .systemBackground
    tableView.separatorStyle = .none
    tableView.keyboardDismissMode = .interactive
    tableView.contentInsetAdjustmentBehavior = .never
    tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 8, right: 0)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseID)

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor)
    ])
  }

  private func configureInputBar() {
    inputBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(inputBar)

    inputBar.onSendText = { [weak self] text in
      self?.viewModel.sendText(text)
    }
    inputBar.onTapAttachment = { [weak self] in
      self?.presentAttachmentMenu()
    }

    inputBarBottomConstraint = inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    NSLayoutConstraint.activate([
      inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      inputBarBottomConstraint!
    ])
  }

  private func configureKeyboardHandling() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillChangeFrame(_:)),
      name: UIResponder.keyboardWillChangeFrameNotification,
      object: nil
    )
  }

  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
      let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
    else { return }

    let endFrame = endFrameValue.cgRectValue
    let endFrameInView = view.convert(endFrame, from: nil)
    let intersection = view.bounds.intersection(endFrameInView)
    let bottomInset = max(0, intersection.height - view.safeAreaInsets.bottom)

    inputBarBottomConstraint?.constant = -bottomInset
    let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
    UIView.animate(withDuration: duration, delay: 0, options: options) {
      self.view.layoutIfNeeded()
      self.scrollToBottom(animated: false)
    }
  }

  private func scrollToBottom(animated: Bool) {
    let messages = viewModel.messages
    guard !messages.isEmpty else { return }
    let indexPath = IndexPath(row: messages.count - 1, section: 0)
    tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
  }

  private func presentAttachmentMenu() {
    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    sheet.addAction(UIAlertAction(title: "Photo or Video", style: .default) { [weak self] _ in
      self?.presentPhotoPicker()
    })
    sheet.addAction(UIAlertAction(title: "File", style: .default) { [weak self] _ in
      self?.presentFilePicker()
    })
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = inputBar
      popover.sourceRect = CGRect(x: inputBar.bounds.midX, y: inputBar.bounds.minY, width: 1, height: 1)
    }
    present(sheet, animated: true)
  }

  private func presentPhotoPicker() {
    var config = PHPickerConfiguration(photoLibrary: .shared())
    config.selectionLimit = 0
    config.filter = .any(of: [.images, .videos])
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    present(picker, animated: true)
  }

  private func presentFilePicker() {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data], asCopy: true)
    picker.allowsMultipleSelection = true
    picker.delegate = self
    present(picker, animated: true)
  }

  private func openURL(_ url: URL) {
    quickLookURL = url
    quickLookController.reloadData()
    present(quickLookController, animated: true)
  }

  private func openMedia(_ media: ChatMessageKind.Media) {
    let vc = MediaPreviewViewController(media: media)
    let nav = UINavigationController(rootViewController: vc)
    nav.modalPresentationStyle = .fullScreen
    present(nav, animated: true)
  }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseID, for: indexPath)
    guard let chatCell = cell as? ChatMessageCell else { return cell }
    chatCell.configure(with: viewModel.messages[indexPath.row])
    chatCell.onRetryTapped = { [weak self] messageID in
      self?.viewModel.retry(messageID: messageID)
    }
    return chatCell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let message = viewModel.messages[indexPath.row]
    if message.deliveryState == .failed, message.author == .me {
      viewModel.retry(messageID: message.id)
      return
    }
    switch message.kind {
    case .file(let file): openURL(file.localURL)
    case .media(let media): openMedia(media)
    case .text: break
    }
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let message = viewModel.messages[indexPath.row]
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      guard let self else { return UIMenu() }

      let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
        if case .text(let text) = message.kind {
          UIPasteboard.general.string = text
        }
      }
      copy.attributes = message.kind.isText ? [] : [.disabled]

      let retry = UIAction(title: "Retry send", image: UIImage(systemName: "arrow.clockwise")) { _ in
        self.viewModel.retry(messageID: message.id)
      }
      retry.attributes = (message.deliveryState == .failed && message.author == .me) ? [] : [.hidden]

      let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
        self.viewModel.deleteMessage(messageID: message.id)
      }

      let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { _ in
        let items: [Any]
        switch message.kind {
        case .text(let text): items = [text]
        case .media(let media): items = [media.localURL]
        case .file(let file): items = [file.localURL]
        }
        self.present(UIActivityViewController(activityItems: items, applicationActivities: nil), animated: true)
      }

      return UIMenu(title: "", children: [copy, retry, share, delete])
    }
  }
}

private extension ChatMessageKind {
  var isText: Bool {
    if case .text = self { return true }
    return false
  }
}

extension ChatViewController: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    dismiss(animated: true)
    guard !results.isEmpty else { return }

    for result in results {
      let provider = result.itemProvider
      if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
        loadPickedFile(provider: provider, preferredType: .image)
      } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
        loadPickedFile(provider: provider, preferredType: .movie)
      }
    }
  }

  private func loadPickedFile(provider: NSItemProvider, preferredType: UTType) {
    provider.loadFileRepresentation(forTypeIdentifier: preferredType.identifier) { [weak self] url, error in
      guard let self, let url, error == nil else { return }
      do {
        let dst = try AttachmentStorage.persistPickedFile(from: url, preferredExtension: preferredType.preferredFilenameExtension)
        DispatchQueue.main.async {
          let media: ChatMessageKind.Media
          if preferredType == .image {
            media = ChatMessageKind.Media(type: .image, localURL: dst, thumbnailURL: nil)
          } else {
            media = ChatMessageKind.Media(type: .video, localURL: dst, thumbnailURL: nil)
          }
          self.viewModel.sendMedia(media)
        }
      } catch {
        // Attachment persist failed — user can retry by picking again.
      }
    }
  }
}

extension ChatViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    for url in urls {
      let filename = url.lastPathComponent
      let type = UTType(filenameExtension: url.pathExtension)
      var size: Int64?
      if let values = try? url.resourceValues(forKeys: [.fileSizeKey]), let fileSize = values.fileSize {
        size = Int64(fileSize)
      }
      do {
        let persisted = try AttachmentStorage.persistPickedFile(from: url, preferredExtension: url.pathExtension)
        let attachment = ChatMessageKind.FileAttachment(localURL: persisted, filename: filename, contentType: type, fileSizeBytes: size)
        viewModel.sendFile(attachment)
      } catch {
        continue
      }
    }
  }
}

extension ChatViewController: QLPreviewControllerDataSource {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int { quickLookURL == nil ? 0 : 1 }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    (quickLookURL ?? URL(fileURLWithPath: "/")) as NSURL
  }
}
