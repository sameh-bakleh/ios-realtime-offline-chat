import UIKit

final class FeaturesViewController: UIViewController {
  private let repository: ChatRepositoryProtocol

  private enum Section: Int, CaseIterable {
    case connectivity
    case appearance
    case inbox
    case chat

    var title: String {
      switch self {
      case .connectivity: return "Connectivity"
      case .appearance: return "Appearance"
      case .inbox: return "Inbox"
      case .chat: return "Chat"
      }
    }
  }

  private enum Row: Hashable {
    case simulateOffline
    case theme
    case pinned
    case unread
    case deliveryStates
    case mediaViewer

    var title: String {
      switch self {
      case .simulateOffline: return "Simulate offline mode"
      case .theme: return "Brand theme"
      case .pinned: return "Pinned section"
      case .unread: return "Unread filter"
      case .deliveryStates: return "Message delivery states"
      case .mediaViewer: return "Media viewer"
      }
    }

    var subtitle: String {
      switch self {
      case .simulateOffline: return "Queue outbound messages and auto-retry when back online."
      case .theme: return "Professional messaging colors and navigation styling."
      case .pinned: return "Keep important chats at the top."
      case .unread: return "Quickly show conversations you haven’t read."
      case .deliveryStates: return "Sending, sent, failed, and retrying with optimistic UI."
      case .mediaViewer: return "Full-screen image zoom + video player."
      }
    }
  }

  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var simulateOffline = false

  init(repository: ChatRepositoryProtocol) {
    self.repository = repository
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Features"
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
}

extension FeaturesViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    Section(rawValue: section)?.title
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch Section(rawValue: section)! {
    case .connectivity: return 1
    case .appearance: return 1
    case .inbox: return 2
    case .chat: return 2
    }
  }

  private func row(for indexPath: IndexPath) -> Row {
    switch Section(rawValue: indexPath.section)! {
    case .connectivity: return .simulateOffline
    case .appearance: return .theme
    case .inbox: return indexPath.row == 0 ? .pinned : .unread
    case .chat: return indexPath.row == 0 ? .deliveryStates : .mediaViewer
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = row(for: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

    if row == .simulateOffline {
      cell.contentConfiguration = nil
      cell.textLabel?.text = row.title
      cell.detailTextLabel?.text = row.subtitle
      let toggle = UISwitch()
      toggle.isOn = simulateOffline
      toggle.addAction(UIAction { [weak self] action in
        guard let self, let sender = action.sender as? UISwitch else { return }
        self.simulateOffline = sender.isOn
        self.repository.setSimulatedOffline(sender.isOn)
      }, for: .valueChanged)
      cell.accessoryView = toggle
      cell.selectionStyle = .none
      return cell
    }

    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.image = UIImage(systemName: "checkmark.seal.fill")
    config.imageProperties.tintColor = AppTheme.brandBlue
    cell.contentConfiguration = config
    cell.accessoryView = nil
    cell.selectionStyle = .none
    return cell
  }
}
