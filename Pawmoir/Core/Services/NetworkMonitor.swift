import Foundation
import Network
import Observation

/// Online/offline banner state. Captions, sync, and checkout need a connection;
/// the diary does not.
@MainActor
@Observable
final class NetworkMonitor {
    private(set) var isOnline: Bool
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "pawmoir.network")

    init() {
        let monitor = NWPathMonitor()
        self.monitor = monitor
        self.isOnline = true
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self?.isOnline = online
            }
        }
        monitor.start(queue: queue)
    }
}
