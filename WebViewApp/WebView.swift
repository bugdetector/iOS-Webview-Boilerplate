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
        
        
        let webview = WKWebView(frame: .zero, configuration: config)
        
        webview.navigationDelegate = context.coordinator
        webview.allowsBackForwardNavigationGestures = false
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
            print("webView didFinish")
            var cookieDict = [String : AnyObject]()
            webview.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    if(cookie.name == "session-token"){
                        print(cookie.value)
                    }
                }
            }
        }
    }
}

