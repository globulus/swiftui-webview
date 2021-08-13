import SwiftUI
import WebKit
import Foundation

public enum WebViewAction {
    case idle,
         load(URLRequest),
         reload,
         goBack,
         goForward
}

public struct WebViewState {
    public internal(set) var isLoading: Bool
    public internal(set) var pageTitle: String?
    public internal(set) var error: Error?
    public internal(set) var canGoBack: Bool
    public internal(set) var canGoForward: Bool
    
    public static let empty = WebViewState(isLoading: false,
                                           pageTitle: nil,
                                           error: nil,
                                           canGoBack: false,
                                           canGoForward: false)
}

public class WebViewCoordinator: NSObject {
    private let webView: WebView
    
    init(webView: WebView) {
        self.webView = webView
    }
    
    func setLoading(_ isLoading: Bool, error: Error? = nil) {
        var newState =  webView.state
        newState.isLoading = isLoading
        if let error = error {
            newState.error = error
        }
        webView.state = newState
    }
}

extension WebViewCoordinator: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setLoading(false)
        
        webView.evaluateJavaScript("document.title") { (response, error) in
            var newState = self.webView.state
            newState.pageTitle = response as? String
            self.webView.state = newState
        }
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        setLoading(false)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        setLoading(false, error: error)
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        setLoading(true)
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        var newState = self.webView.state
        newState.isLoading = true
        newState.canGoBack = webView.canGoBack
        newState.canGoForward = webView.canGoForward
        self.webView.state = newState
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let host = navigationAction.request.url?.host {
            if self.webView.restrictedPages?.first(where: { host.contains($0) }) != nil {
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

#if os(iOS)
public struct WebView: UIViewRepresentable {
    @Binding var action: WebViewAction
    @Binding var state: WebViewState
    let restrictedPages: [String]?
    
    public init(action: Binding<WebViewAction>,
                state: Binding<WebViewState>,
                restrictedPages: [String]? = nil) {
        _action = action
        _state = state
        self.restrictedPages = restrictedPages
    }
    
    public func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(webView: self)
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        switch action {
        case .idle:
            break
        case .load(let request):
            uiView.load(request)
        case .reload:
            uiView.reload()
        case .goBack:
            uiView.goBack()
        case .goForward:
            uiView.goForward()
        }
        action = .idle
    }
}
#endif

#if os(macOS)
public struct WebView: NSViewRepresentable {
    @Binding var action: WebViewAction
    @Binding var state: WebViewState
    let restrictedPages: [String]?
    
    public init(action: Binding<WebViewAction>,
                state: Binding<WebViewState>,
                restrictedPages: [String]? = nil) {
        _action = action
        _state = state
        self.restrictedPages = restrictedPages
    }
    
    public func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(webView: self)
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    public func updateNSView(_ uiView: WKWebView, context: Context) {
        switch action {
        case .idle:
            break
        case .load(let request):
            uiView.load(request)
        case .reload:
            uiView.reload()
        case .goBack:
            uiView.goBack()
        case .goForward:
            uiView.goForward()
        }
        action = .idle
    }
}
#endif

struct WebViewTest: View {
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    @State private var address = "https://www.google.com"
    
    var body: some View {
        VStack {
            titleView
            navigationToolbar
            errorView
            Divider()
            WebView(action: $action,
                    state: $state,
                    restrictedPages: ["apple.com"])
            Spacer()
        }
    }
    
    private var titleView: some View {
        Text(state.pageTitle ?? "Load a page")
            .font(.system(size: 24))
    }
    
    private var navigationToolbar: some View {
        HStack(spacing: 10) {
            TextField("Address", text: $address)
            if state.isLoading {
                if #available(iOS 14, macOS 10.15, *) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Loading")
                }
            }
            Spacer()
            Button("Go") {
                if let url = URL(string: address) {
                    action = .load(URLRequest(url: url))
                }
            }
            Button(action: {
                action = .reload
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.large)
            }
            if state.canGoBack {
                Button(action: {
                    action = .goBack
                }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
            if state.canGoForward {
                Button(action: {
                    action = .goForward
                }) {
                Image(systemName: "chevron.right")
                    .imageScale(.large)
                    
                }
            }
        }.padding()
    }
    
    private var errorView: some View {
        Group {
            if let error = state.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            }
        }
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebViewTest()
    }
}
