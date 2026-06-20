import UIKit

enum AppTheme {
  static var brandBlue: UIColor { UIColor(named: "BrandBlue") ?? .systemBlue }
  static var brandSurface: UIColor { UIColor(named: "BrandSurface") ?? .systemBackground }
  static var brandOrange: UIColor { UIColor(named: "BrandOrange") ?? .systemOrange }

  static func apply() {
    let standard = UINavigationBarAppearance()
    standard.configureWithOpaqueBackground()
    standard.backgroundColor = brandSurface
    standard.shadowColor = UIColor.separator.withAlphaComponent(0.45)
    standard.titleTextAttributes = [.foregroundColor: UIColor.label]
    standard.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

    let scrollEdge = UINavigationBarAppearance()
    scrollEdge.configureWithOpaqueBackground()
    scrollEdge.backgroundColor = brandSurface
    scrollEdge.shadowColor = .clear
    scrollEdge.titleTextAttributes = standard.titleTextAttributes
    scrollEdge.largeTitleTextAttributes = standard.largeTitleTextAttributes

    UINavigationBar.appearance().standardAppearance = standard
    UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge
    UINavigationBar.appearance().compactAppearance = standard
    UINavigationBar.appearance().tintColor = brandBlue

    UIPageControl.appearance().currentPageIndicatorTintColor = brandBlue
  }
}
