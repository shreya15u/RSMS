import SwiftUI
import WebKit

struct JitsiWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(AppColors.background)
        webView.scrollView.isScrollEnabled = false // Prevent bouncy scrolling
        webView.uiDelegate = context.coordinator // Assign the delegate here
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    class Coordinator: NSObject, WKUIDelegate {
        var parent: JitsiWebView
        
        init(_ parent: JitsiWebView) {
            self.parent = parent
        }
        
        @available(iOS 15.0, *)
        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            // Auto-grant camera and microphone access to avoid repeated prompts
            decisionHandler(.grant)
        }
    }
}
