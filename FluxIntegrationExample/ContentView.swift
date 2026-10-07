import SwiftUI

struct ContentView: View {
    /// The id of a flow in your Flux account, supplied by Optioryx.
    @AppStorage("flowId") private var flowId = ""
    /// Optional: a barcode your app already knows, stored on the Flux item.
    @State private var code = ""
    @State private var result: FluxLink.Result?
    @Environment(\.openURL) private var openURL

    /// Registered in Info.plist (CFBundleURLSchemes). Use your own scheme or universal link.
    private let callback = URL(string: "fluxexample://result")!

    var body: some View {
        NavigationStack {
            Form {
                Section("Request") {
                    TextField("Flow id", text: $flowId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Barcode (optional)", text: $code)
                    Button("Start scan in Flux") {
                        openURL(FluxLink.openURL(flowId: flowId, callback: callback, code: code.isEmpty ? nil : code))
                    }
                    .disabled(flowId.isEmpty)
                }

                if let result {
                    Section("Result") { ResultView(result: result) }
                }
            }
            .navigationTitle("Flux integration")
        }
        .onOpenURL { url in
            result = FluxLink.Result(url: url)
        }
    }
}

private struct ResultView: View {
    let result: FluxLink.Result

    var body: some View {
        switch result {
        case .completed(let json):
            LabeledContent("Status", value: "completed")
            if let d = FluxLink.dimensions(in: json) {
                LabeledContent("Dimensions", value: "\(d.width) × \(d.height) × \(d.depth) \(d.unit)")
            }
            Text(prettyPrinted(json))
                .font(.caption.monospaced())
                .textSelection(.enabled)
        case .cancelled:
            LabeledContent("Status", value: "cancelled")
        case .error(let reason):
            LabeledContent("Status", value: "error")
            LabeledContent("Reason", value: reason)
        }
    }

    private func prettyPrinted(_ json: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: json),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
            return String(decoding: json, as: UTF8.self)
        }
        return String(decoding: data, as: UTF8.self)
    }
}

#Preview { ContentView() }
