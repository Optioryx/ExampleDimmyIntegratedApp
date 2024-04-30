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
                    // (or custom URL type, but this will prompt the user
                    // if they actually want to open another app so this is less seamless)
                    // App Links: https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app
                    // Custom URL type: https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app
                    callbackBaseUrl: "https://dimmy.api.optioryx.com/callback"
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

#Preview {
    ContentView()
}

func openDimmy(flowId: String, callbackBaseUrl: String) {
    guard let url = URL(string: "https://dimmy.api.optioryx.com/open?flow=\(flowId)&callback=\(Base64.encode(callbackBaseUrl))") else {
        return
    }
    UIApplication.shared.open(url)
}
