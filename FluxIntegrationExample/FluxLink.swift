import Foundation

/// Everything your app needs to start a Flux flow and read its result.
/// Copy this file into your own app; it has no dependencies.
///
/// Contract: https://github.com/Optioryx/ExampleDimmyIntegratedApp#the-link-contract
enum FluxLink {
    /// Flux's public host. Optioryx staff testing against the dev backend
    /// set this to "flux-dev.api.optioryx.com".
    static let host = "flux.api.optioryx.com"

    /// The link that opens Flux on the flow named `flowName` (exactly as in the
    /// Flux web app). Pass it to `UIApplication.shared.open` (or SwiftUI's `openURL`).
    static func openURL(flowName: String, callback: URL, code: String? = nil) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/open"
        components.queryItems = [
            URLQueryItem(name: "flowName", value: flowName),
            URLQueryItem(name: "callback", value: callback.absoluteString),
        ] + (code.map { [URLQueryItem(name: "code", value: $0)] } ?? [])
        // URLComponents leaves "+" alone, but many URL parsers read it as a space.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url!
    }

    /// What Flux sends back to your `callback`.
    enum Result: Equatable {
        /// The flow finished. `json` is the captured item.
        case completed(json: Data)
        /// The operator left the flow without finishing it.
        case cancelled
        /// The flow could not start: "invalid_request", "not_logged_in" or "flow_unavailable".
        case error(String)

        /// nil when `url` is not a Flux callback (or its response is damaged).
        init?(url: URL) {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

            switch value("status") {
            case "completed":
                guard let response = value("response"), let json = FluxLink.decodeBase64URL(response) else { return nil }
                self = .completed(json: json)
            case "cancelled":
                self = .cancelled
            case "error":
                self = .error(value("error") ?? "unknown")
            default:
                return nil
            }
        }
    }

    struct Dimensions: Decodable, Equatable {
        let width: Double
        let height: Double
        let depth: Double
        let unit: String
    }

    /// The first measured box in a completed result, if the flow had a dimensioning step.
    static func dimensions(in json: Data) -> Dimensions? {
        struct Item: Decodable {
            struct Dimensioning: Decodable { let dimensions: Dimensions? }
            let dimensioning: [Dimensioning]
        }
        return (try? JSONDecoder().decode(Item.self, from: json))?.dimensioning.first?.dimensions
    }

    /// Base64url (RFC 4648 section 5) without padding, as Flux sends it.
    static func decodeBase64URL(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }
}
