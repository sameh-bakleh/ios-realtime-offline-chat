import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)
    let inbox = ConversationsListViewController()
    let nav = UINavigationController(rootViewController: inbox)
    window.rootViewController = nav
    window.makeKeyAndVisible()
    self.window = window
  }
}

