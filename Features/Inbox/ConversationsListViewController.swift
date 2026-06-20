import Combine
import UIKit

final class ConversationsListViewController: UIViewController {
  private let viewModel: InboxViewModel
  private var cancellables = Set<AnyCancellable>()

  private var isSearching: Bool { !(navigationItem.searchController?.searchBar.text?.isEmpty ?? true) }
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)

  init(viewModel: InboxViewModel = InboxViewModel(repository: AppEnvironment.shared.chatRepository)) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Messaging"
    view.backgroundColor = .systemBackground

    configureSearch()
    configureTable()
    configureNav()
    bindViewModel()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.reload()
    tableView.reloadData()
  }

  private func bindViewModel() {
    viewModel.$conversations
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in self?.tableView.reloadData() }
      .store(in: &cancellables)

    viewModel.$connectivity
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.updateConnectivityBanner(state)
      }
      .store(in: &cancellables)
  }

  private func updateConnectivityBanner(_ state: ConnectivityState) {
    switch state {
    case .online:
      navigationItem.prompt = nil
    case .offline:
      navigationItem.prompt = "Offline — messages queue locally and retry when online"
    }
  }

  private func configureNav() {
    navigationItem.largeTitleDisplayMode = .never
    navigationController?.navigationBar.prefersLargeTitles = false
    navigationItem.title = "Messaging"

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(didTapFeatures)),
      UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(didTapCompose))
    ]

    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
      style: .plain,
      target: self,
      action: #selector(didTapFilters)
    )
  }

  @objc private func didTapFeatures() {
    let vc = FeaturesViewController(repository: AppEnvironment.shared.chatRepository)
    navigationController?.pushViewController(vc, animated: true)
  }

  @objc private func didTapFilters() {
    let sheet = UIAlertController(title: "Inbox", message: nil, preferredStyle: .actionSheet)
    for filter in InboxViewModel.InboxFilter.allCases {
      sheet.addAction(UIAlertAction(title: filter.rawValue, style: .default) { [weak self] _ in
        self?.viewModel.setFilter(filter)
        self?.tableView.reloadData()
      })
    }
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    if let popover = sheet.popoverPresentationController {
      popover.barButtonItem = navigationItem.leftBarButtonItem
    }
    present(sheet, animated: true)
  }

  @objc private func didTapCompose() {
    let conversation = viewModel.createConversation(title: "New chat")
    tableView.reloadData()
    open(conversation)
  }

  private func configureSearch() {
    let search = UISearchController(searchResultsController: nil)
    search.obscuresBackgroundDuringPresentation = false
    search.searchResultsUpdater = self
    search.searchBar.placeholder = "Search messages"
    navigationItem.searchController = search
    navigationItem.hidesSearchBarWhenScrolling = false
  }

  private func configureTable() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .systemBackground
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 72
    tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseID)
    tableView.dataSource = self
    tableView.delegate = self

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func open(_ conversation: Conversation) {
    let chat = ChatViewController(
      viewModel: ChatViewModel(
        conversationID: conversation.id,
        conversationTitle: conversation.title,
        repository: AppEnvironment.shared.chatRepository
      )
    )
    navigationController?.pushViewController(chat, animated: true)
    viewModel.markRead(conversationID: conversation.id)
  }
}

extension ConversationsListViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.pinnedSection(isSearching: isSearching).isEmpty ? 1 : 2
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if numberOfSections(in: tableView) == 1 { return nil }
    return section == 0 ? "Pinned" : "Recent"
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let pinned = viewModel.pinnedSection(isSearching: isSearching)
    if pinned.isEmpty { return viewModel.displayedConversations(isSearching: isSearching).count }
    let other = viewModel.recentSection(isSearching: isSearching)
    return section == 0 ? pinned.count : other.count
  }

  private func conversation(at indexPath: IndexPath) -> Conversation {
    let pinned = viewModel.pinnedSection(isSearching: isSearching)
    if pinned.isEmpty { return viewModel.displayedConversations(isSearching: isSearching)[indexPath.row] }
    let other = viewModel.recentSection(isSearching: isSearching)
    return indexPath.section == 0 ? pinned[indexPath.row] : other[indexPath.row]
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseID, for: indexPath)
    guard let c = cell as? ConversationCell else { return cell }
    c.configure(with: conversation(at: indexPath))
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    open(conversation(at: indexPath))
  }

  func tableView(
    _ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    let conv = conversation(at: indexPath)

    let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
      self?.viewModel.deleteConversation(conversationID: conv.id)
      tableView.reloadData()
      completion(true)
    }

    let pinTitle = conv.pinned ? "Unpin" : "Pin"
    let pin = UIContextualAction(style: .normal, title: pinTitle) { [weak self] _, _, completion in
      self?.viewModel.togglePinned(conversationID: conv.id)
      tableView.reloadData()
      completion(true)
    }
    pin.backgroundColor = AppTheme.brandOrange

    let config = UISwipeActionsConfiguration(actions: [delete, pin])
    config.performsFirstActionWithFullSwipe = true
    return config
  }
}

extension ConversationsListViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    viewModel.setSearchText(searchController.searchBar.text ?? "")
    tableView.reloadData()
  }
}
