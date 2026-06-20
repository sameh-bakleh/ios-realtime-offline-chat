import Combine
import Foundation

protocol ConnectivityMonitoring: AnyObject {
  var state: ConnectivityState { get }
  var statePublisher: AnyPublisher<ConnectivityState, Never> { get }
}

/// Bridges transport offline simulation to repository retry logic.
final class ConnectivityMonitor: ConnectivityMonitoring {
  @Published private(set) var state: ConnectivityState = .online

  var statePublisher: AnyPublisher<ConnectivityState, Never> {
    $state.eraseToAnyPublisher()
  }

  private weak var transport: ChatTransport?

  init(transport: ChatTransport) {
    self.transport = transport
  }

  func refreshFromTransport() {
    let online = !(transport?.isSimulatedOffline ?? false)
    state = online ? .online : .offline
  }

  func setSimulatedOffline(_ offline: Bool) {
    transport?.isSimulatedOffline = offline
    state = offline ? .offline : .online
  }
}
