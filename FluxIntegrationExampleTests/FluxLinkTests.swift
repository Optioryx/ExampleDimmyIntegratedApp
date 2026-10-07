import Foundation
import Testing
@testable import FluxIntegrationExample

struct FluxLinkTests {

    // MARK: opening Flux

    @Test func openURL_encodesEveryParameter() throws {
        let url = FluxLink.openURL(flowId: "65f0c1", callback: URL(string: "myapp://flux?order=A+1&x=y")!, code: "BOX 7")
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(url.host == "flux.api.optioryx.com")
        #expect(url.path == "/open")
        #expect(items.first { $0.name == "flowId" }?.value == "65f0c1")
        #expect(items.first { $0.name == "callback" }?.value == "myapp://flux?order=A+1&x=y")
        #expect(items.first { $0.name == "code" }?.value == "BOX 7")
        // "+", "&", "?" inside the callback must not leak into Flux's own query.
        #expect(items.count == 3)
        #expect(!url.absoluteString.contains("A+1"))
    }

    @Test func openURL_omitsMissingCode() {
        let url = FluxLink.openURL(flowId: "f", callback: URL(string: "myapp://r")!)
        #expect(!url.absoluteString.contains("code="))
    }

    // MARK: reading the result

    @Test func result_completed_decodesBase64URL() {
        // "-_8" is base64url for the bytes 0xFB 0xFF (standard Base64: "+/8=").
        let result = FluxLink.Result(url: URL(string: "myapp://r?status=completed&response=-_8")!)
        #expect(result == .completed(json: Data([0xFB, 0xFF])))
    }

    @Test func result_completed_roundTripsJSON() {
        let json = Data(#"{"dimensioning":[{"dimensions":{"width":1.5,"height":2,"depth":3,"unit":"m"}}]}"#.utf8)
        let b64 = json.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let result = FluxLink.Result(url: URL(string: "myapp://r?order=7&status=completed&response=\(b64)")!)
        #expect(result == .completed(json: json))
    }

    @Test func result_cancelled() {
        #expect(FluxLink.Result(url: URL(string: "myapp://r?status=cancelled")!) == .cancelled)
    }

    @Test(arguments: ["invalid_request", "not_logged_in", "flow_unavailable"])
    func result_error(reason: String) {
        #expect(FluxLink.Result(url: URL(string: "myapp://r?status=error&error=\(reason)")!) == .error(reason))
    }

    @Test func result_malformedResponse_isNil() {
        #expect(FluxLink.Result(url: URL(string: "myapp://r?status=completed&response=%25%25")!) == nil)
        #expect(FluxLink.Result(url: URL(string: "myapp://r?status=completed")!) == nil)
    }

    @Test func result_notAFluxCallback_isNil() {
        #expect(FluxLink.Result(url: URL(string: "myapp://r?foo=bar")!) == nil)
    }

    // MARK: dimensions

    @Test func dimensions_readsFirstDimensioning() {
        let json = Data(#"{"dimensioning":[{"dimensions":{"width":1.5,"height":2,"depth":3,"unit":"m"}}]}"#.utf8)
        #expect(FluxLink.dimensions(in: json) == FluxLink.Dimensions(width: 1.5, height: 2, depth: 3, unit: "m"))
    }

    @Test func dimensions_noneCaptured_isNil() {
        #expect(FluxLink.dimensions(in: Data(#"{"dimensioning":[]}"#.utf8)) == nil)
    }
}
