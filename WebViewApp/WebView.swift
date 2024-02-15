//
//  MyWebView.swift
//  webview-test

import SwiftUI
import WebKit
import Combine


struct WebView: UIViewRepresentable {
    
    let url: URL?
    @ObservedObject var viewModel: WebViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        print("makeUIView")
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        config.dataDetectorTypes = [.all]
        
        
        let webview = WKWebView(frame: .zero, configuration: config)
        
        webview.navigationDelegate = context.coordinator
        webview.allowsBackForwardNavigationGestures = true
        webview.scrollView.isScrollEnabled = true
        
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let myUrl = url else {
            return
        }
        let request = URLRequest(url: myUrl)
        uiView.load(request)
    }
    
    class Coordinator : NSObject, WKNavigationDelegate {
        var parent: WebView
        var callbackValueFromNative: AnyCancellable? = nil
        
        init(_ uiWebView: WebView) {
            self.parent = uiWebView
        }
        
        deinit {
            callbackValueFromNative?.cancel()
        }
        
        func webView(_ webview: WKWebView, didFinish: WKNavigation!) {
            webview.customUserAgent = "iOSApp"
            
            webview.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    if(cookie.name == "session-token"){
                        print(cookie.value)
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                         decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard
                let url = navigationAction.request.url else {
                    decisionHandler(.cancel)
                    return
            }
        
            if (!url.absoluteString.starts(with: Constants.BASE_URL)) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            let mime = navigationResponse.response.mimeType
            if navigationResponse.response.mimeType == "text/html" {
                decisionHandler(.allow)
            } else {
                decisionHandler(.download)
            }
        }
    }
}

