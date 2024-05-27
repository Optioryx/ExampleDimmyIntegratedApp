import SwiftUI

struct ContentView: View {
    @State private var showAlert = false
    @State private var dimmyResponse: String = ""
    
    var body: some View {
        VStack {
            Button("Start scan", action: {
                openDimmy(
                    // Replace this with a flowId that you made in the
                    // Dimmy webapp
                    flowId: "default",
                    // Replace this with your own registered callback url
                    // to open your app again after completing the flow.
                    // (or custom URL type, but this will prompt the user
                    // if they actually want to open another app so this is less seamless)
                    // App Links: https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app
                    // Custom URL type: https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app
                    callbackBaseUrl: "https://dimmy.api.optioryx.com/callback",
                    // Optionally provide a (bar)code, so the resulting scans
                    // can be identified on the Dimmy platform
                    code: "ABCD1234"
                )
            })
        }
        .padding()
        .onOpenURL { incomingUrl in
            guard let components = URLComponents(url: incomingUrl, resolvingAgainstBaseURL: true) else {
                print("Invalid URL")
                return
            }
            
            guard let params = components.queryItems,
                  let responseBase64 = params.first(where: { $0.name == "response"})?.value,
                  let response = try? Base64.decode(responseBase64) else {
                return
            }
            
            dimmyResponse = response
            showAlert = true
        }
        .alert("Response", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(dimmyResponse)
        }
    }
}

func openDimmy(flowId: String, callbackBaseUrl: String, code: String? = nil) {
    var rawUrl = "https://dimmy.api.optioryx.com/open?flow=\(flowId)&callback=\(Base64.encode(callbackBaseUrl))"
    if let code = code {
        rawUrl = "\(rawUrl)&code=\(code)"
    }
    guard let url = URL(string: rawUrl) else {
        return
    }
    UIApplication.shared.open(url)
}
