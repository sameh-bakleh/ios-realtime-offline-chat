import AVKit
import UIKit

final class MediaPreviewViewController: UIViewController, UIScrollViewDelegate {
  private let media: ChatMessageKind.Media

  private let scrollView = UIScrollView()
  private let imageView = UIImageView()
  private var playerController: AVPlayerViewController?

  init(media: ChatMessageKind.Media) {
    self.media = media
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    let close = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
      self?.dismiss(animated: true)
    })
    navigationItem.rightBarButtonItem = close

    switch media.type {
    case .image:
      setupImage()
    case .video:
      setupVideo()
    }
  }

  private func setupImage() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.backgroundColor = .black
    scrollView.minimumZoomScale = 1
    scrollView.maximumZoomScale = 3
    scrollView.delegate = self
    view.addSubview(scrollView)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.image = UIImage(contentsOfFile: media.localURL.path)
    scrollView.addSubview(imageView)

    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
      imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
    ])
  }

  private func setupVideo() {
    let player = AVPlayer(url: media.localURL)
    let playerController = AVPlayerViewController()
    playerController.player = player
    self.playerController = playerController

    addChild(playerController)
    playerController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(playerController.view)
    playerController.didMove(toParent: self)

    NSLayoutConstraint.activate([
      playerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      playerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      playerController.view.topAnchor.constraint(equalTo: view.topAnchor),
      playerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    player.play()
  }

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageView
  }
}

