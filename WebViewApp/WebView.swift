//
//  MyWebView.swift
//  webview-test

import SwiftUI
import WebKit
import Combine


struct WebView: UIViewRepresentable {
    
    let url: URL?
    @ObservedObject var viewModel: WebViewModel
    
    var navigatorGeolocation = NavigatorGeolocation()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Initialize configuration
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
        
        navigatorGeolocation.setWebView(webView: webview)
        
        return webview
    }
    
    // Initialize webview with url
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let myUrl = url else {
            return
        }
        let request = URLRequest(url: myUrl)
        uiView.load(request)
    }
    
    class Coordinator : NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ uiWebView: WebView) {
            self.parent = uiWebView
        }
        
        // initial,ze webview
        func webView(_ webview: WKWebView, didFinish: WKNavigation!) {
            webview.customUserAgent = "ios-web-view"
            
            webview.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    if(cookie.name == "session-token"){
                        print(cookie.value)
                    }
                }
            }
            webview.evaluateJavaScript(parent.navigatorGeolocation.getJavaScriptToEvaluate())
        }
        
        // Open in onather app if url is not starts with base url
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
        
        // Download file if respons is not html
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.response.mimeType == "text/html" {
                decisionHandler(.allow)
            } else {
                guard
                    let url = navigationResponse.response.url else {
                        decisionHandler(.cancel)
                        return
                }
                UIApplication.shared.open(
                    url,
                    options: [:],
                    completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }
        
        
    }
}

