import Foundation

/// Composition root — injectable for production and unit tests.
final class AppEnvironment {
  static let shared = AppEnvironment()

  let chatRepository: ChatRepositoryProtocol

  private init() {
    let transport = MockChatTransport(
      latencySeconds: MockChatConfiguration.simulatedLatencySeconds,
      failureRate: MockChatConfiguration.simulatedFailureRate
    )
    let store = LocalChatStore()
    let connectivity = ConnectivityMonitor(transport: transport)
    chatRepository = ChatRepository(store: store, transport: transport, connectivity: connectivity)
  }

  /// Test / preview assembly with custom dependencies.
  init(store: LocalChatStore, transport: ChatTransport) {
    let connectivity = ConnectivityMonitor(transport: transport)
    chatRepository = ChatRepository(store: store, transport: transport, connectivity: connectivity)
  }
}
