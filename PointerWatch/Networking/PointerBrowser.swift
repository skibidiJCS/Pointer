import Foundation
import Network

@MainActor
final class PointerBrowser {
    var onUpdate: (([DiscoveredMac]) -> Void)?
    var onError: ((String) -> Void)?

    private let queue = DispatchQueue(label: "com.pointer.watch.browser", qos: .userInitiated)
    private var browser: NWBrowser?

    func start() {
        guard browser == nil else {
            return
        }

        let descriptor = NWBrowser.Descriptor.bonjourWithTXTRecord(
            type: PointerConstants.serviceType,
            domain: nil
        )
        let browser = NWBrowser(
            for: descriptor,
            using: PointerNetworkParameters.make()
        )
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let macs = results.compactMap(Self.makeMac).sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            DispatchQueue.main.async {
                self?.onUpdate?(macs)
            }
        }
        browser.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                self?.handle(state)
            }
        }
        self.browser = browser
        browser.start(queue: queue)
    }

    func stop() {
        browser?.cancel()
        browser = nil
        onUpdate?([])
    }

    nonisolated private static func makeMac(from result: NWBrowser.Result) -> DiscoveredMac? {
        guard case .bonjour(let record) = result.metadata,
              let id = record["id"] else {
            return nil
        }
        let name = record["name"] ?? endpointName(result.endpoint)
        return DiscoveredMac(id: id, name: name, endpoint: result.endpoint)
    }

    nonisolated private static func endpointName(_ endpoint: NWEndpoint) -> String {
        if case .service(let name, _, _, _) = endpoint {
            return name
        }
        return "Mac"
    }

    private func handle(_ state: NWBrowser.State) {
        switch state {
        case .waiting(let error):
            onError?(error.debugDescription)
        case .failed(let error):
            browser = nil
            onError?(error.debugDescription)
        default:
            break
        }
    }
}
